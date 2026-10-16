#!/bin/bash -e

## Dependency versions

v_sdk=9123335_latest
v_ndk=30.0.16248370
v_sdk_build_tools=34.0.0

v_libass=0.17.5
v_harfbuzz=14.6.0
v_fribidi=1.0.17
v_freetype=2-15-0
v_mbedtls=3.6.7
v_dav1d=1.5.4
v_libxml2=2.15.4
v_ffmpeg=24e860f6d3c4f2ebae65ed7649e2a8860d512879
v_mpv=c3ac7f39514c7f45bc38a18e66887240539ee33c
v_libplacebo=1dd022687b9ac1dd996855b51433bf770ae76aab
v_lcms2=lcms2.19.1
v_libogg=1.3.5
v_libvorbis=1.3.7
v_libvpx=1.13.0
v_libx264=023112c6f2f575c72e9f26274d183b70996fb542
v_fftools_ffi=10070acb2c090edda86dba431f6c281145ceb221
v_libsmb2=6.0.0
v_media_kit_android_helper=b768ce102cfa9b5ddec618bb939d689d1b0899fa
v_gas_preprocessor=ac1836309c2e77023c228b7184485597286289d3

## Pinned commit SHAs for tag-based clones
sha_mbedtls=068ff080b369adfac81509f9b57b2afabaf82dc5
sha_dav1d=54706fc6bc0cdecab7e9593974a4039cc038fca7
sha_libxml2=96498992efa48d52b0e8b83058bd88dbdaf153c1
sha_libvpx=d6eb9696aa72473c1a11d34d928d35a3acc0c9a9
sha_freetype=37515cf56ba3349656049edbed89ffc6f6466f2d
sha_fribidi=b93119f5fdc7ea47672cc304c1455ffa6dfe7536
sha_harfbuzz=c7a7457b7385f33178e8cf87615ca077a810bbe7
sha_libass=4a05d8127f525943ebf45fdc6497c9e665947f0d
sha_lcms2=21c582a594fe5279f90c0b93437c398f93bf62b0


## Dependency tree
# I would've used a dict but putting arrays in a dict is not a thing

dep_mbedtls=()
dep_dav1d=()
dep_libvorbis=(libogg)
dep_libsmb2=()
if [ -n "$ENCODERS_GPL" ]; then
	dep_ffmpeg=(mbedtls dav1d libxml2 libvorbis libvpx libx264 libsmb2)
else
	dep_ffmpeg=(mbedtls dav1d libxml2 libsmb2)
fi
dep_freetype2=()
dep_fribidi=()
dep_harfbuzz=()
dep_libass=(freetype fribidi harfbuzz)
dep_lua=()
dep_shaderc=()
dep_libplacebo=(shaderc lcms2)
if [ -n "$ENCODERS_GPL" ]; then
	dep_mpv=(ffmpeg libass libplacebo fftools_ffi)
else
	dep_mpv=(ffmpeg libass libplacebo)
fi
