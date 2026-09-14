
iina:

部分 dylib 是 source?
```shell
Targets/iina/Sources/iina/MPVController.swift:152:29: error: cannot find 'MPV_FORMAT_FLAG' in scope
 150 |     MPVOption.Equalizer.saturation: MPV_FORMAT_INT64,
 151 |     MPVOption.Window.fullscreen: MPV_FORMAT_FLAG,
 152 |     MPVOption.Window.ontop: MPV_FORMAT_FLAG,
     |                             `- error: cannot find 'MPV_FORMAT_FLAG' in scope
 153 |     MPVOption.Window.windowScale: MPV_FORMAT_DOUBLE,
 154 |     MPVProperty.mediaTitle: MPV_FORMAT_STRING,
```

plist 有一些 $(xxx) 需要一些取代
可以在 bazel 或者 swift 層處理

