#!/bin/bash -e

. ../../include/depinfo.sh
. ../../include/path.sh

if [ "$1" == "build" ]; then
	true
elif [ "$1" == "clean" ]; then
	rm -rf _build$ndk_suffix
	exit 0
else
	exit 255
fi

# ── libsmb2 post-install fixes (every platform) ─────────────────────────────
# Fix 1 — libsmb2.h uses size_t/uint8_t/SMB2_GUID_SIZE without including the
#         needed headers. Inject the missing includes.
# Fix 2 — installed .pc misses the smb2/ include subdir. On Apple platforms,
#         also append the framework set GSS+CoreFoundation+resolv (+ krb5 on
#         macOS only) needed by Kerberos symbols.
# Usage: apply_libsmb2_post_install_fixes <prefix> <platform>
#        platform: macos | ios | linux
apply_libsmb2_post_install_fixes() {
  local prefix="$1" platform="$2"
  local hdr="$prefix/include/smb2/libsmb2.h"
  local pc="$prefix/lib/pkgconfig/libsmb2.pc"

  # `-i` flavor depends on the build HOST (where sed runs), not the
  # target platform of the binary. BSD sed (macOS) needs an empty
  # argument; GNU sed (Linux) takes none.
  local sed_inplace=(-i)
  [[ "$(uname -s)" == "Darwin" ]] && sed_inplace=(-i '')

  if [[ -f "$hdr" ]] && ! grep -q 'stddef.h' "$hdr"; then
    # Inject the missing system includes at line 1. BSD sed's `1i\`
    # requires every continuation line to end with a backslash AND
    # the final line to NOT have a trailing newline before the
    # closing quote — incompatible with GNU's looser form. Use a
    # here-doc-built temp file instead so the script is portable
    # across both seds without quoting tricks.
    local injected
    injected="$(mktemp)"
    {
      printf '#include <time.h>\n'
      printf '#include <stdint.h>\n'
      printf '#include <stddef.h>\n'
      printf '#include "smb2.h"\n'
      cat "$hdr"
    } > "$injected"
    mv "$injected" "$hdr"
  fi

  if [[ -f "$pc" ]] && ! grep -q 'includedir}/smb2' "$pc"; then
    sed "${sed_inplace[@]}" 's|Cflags: -I${includedir}|Cflags: -I${includedir} -I${includedir}/smb2|' "$pc"
    case "$platform" in
      macos)
        sed "${sed_inplace[@]}" 's|Libs: -L${libdir} -lsmb2|Libs: -L${libdir} -lsmb2 -framework GSS -framework CoreFoundation -lresolv -lkrb5|' "$pc"
        ;;
      ios)
        sed "${sed_inplace[@]}" 's|Libs: -L${libdir} -lsmb2|Libs: -L${libdir} -lsmb2 -framework GSS -framework CoreFoundation -lresolv|' "$pc"
        ;;
    esac
  fi
}

# Fix: compat.c uses ENXIO under __ANDROID__ without including errno.h.
# The file already has #include <errno.h> but only inside #if _WINDOWS blocks.
# We need an unconditional include at the top of the file.
compat="./lib/compat.c"
if [[ -f "$compat" ]] && ! head -3 "$compat" | grep -q 'errno.h'; then
  sed -i.bak '1a\
#include <errno.h>
' "$compat" && rm -f "$compat.bak"
fi
dir=$PWD
mkdir -p _build$ndk_suffix
pushd _build$ndk_suffix >/dev/null
cmake $dir \
  -DCMAKE_TOOLCHAIN_FILE="$ANDROID_HOME/ndk/$v_ndk/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI="$android_abi" \
  -DANDROID_PLATFORM=android-26 \
  -DANDROID_STL=c++_static \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_POLICY_DEFAULT_CMP0074=NEW \
  -DCMAKE_FIND_ROOT_PATH=$prefix_dir \
  -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_INSTALL_LIBDIR=lib
make -j"$cores"
make DESTDIR="$prefix_dir" install
apply_libsmb2_post_install_fixes "$prefix_dir" "linux"
popd >/dev/null