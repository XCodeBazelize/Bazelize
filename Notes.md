
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

plist 的 `$(xxx)`：專案自己宣告的（pbxproj／xcconfig）與 Xcode 從 toolchain 帶入的
（`SDK_VERSION`、`XCODE_VERSION_*`、`SDK_NAME`、`PLATFORM_NAME`、`CONFIGURATION`）
都在 Swift 層取代掉了，剩下 `plisttool` 自己認的那幾個原樣交給 rules_apple。
只存在於 CI 環境或 secret 的設定仍然解不出來——那種 key 會被丟掉並具名回報。
