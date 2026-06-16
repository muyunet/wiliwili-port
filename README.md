## Notes
Thanks to [xfangfang](https://github.com/xfangfang) for creating wiliwili and making it available for free!

## Controls

| Button | Action |
|--|--| 
| D-pad / Left Analog | Navigate / Move Cursor |
| A | Confirm / Select / Play / Pause |
| B | Back / Cancel |
| X | Option Menu / Subtitles / Quality settings |
| Y | Toggle Danmaku |
| L1 / R1 | Switch Tabs |
| L2 / R2 | Skip Backward / Skip Forward |
| SELECT + START | Exit App |

## Compile

Built inside the PortMaster aarch64 Docker image (`portmaster-builder:aarch64-latest`).

```shell
git clone --recursive -b yoga https://github.com/xfangfang/wiliwili
cd wiliwili
cmake -B build -G Ninja \
  -DPLATFORM_DESKTOP=ON \
  -DUSE_SDL2=ON \
  -DUSE_GL2=ON \
  -DUSE_SYSTEM_CURL=OFF \
  -DCMAKE_BUILD_TYPE=Release
cmake --build build
```

SDL2, libwebp, OpenSSL, zlib, libcurl are all linked statically.
Only libmpv + ffmpeg codecs are bundled as shared libs in `wiliwili/libs.aarch64/`.
The launcher uses PortMaster's Westonpack runtime for display output.
