
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

CI（`.github/workflows/swift.yml`）目前沒跑的：

- **iina**：matrix 裡註解掉，等上面那條 dylib 的問題解掉、在 runner 上綠過再打開。
- **MacPass**：需要 submodule 加 `carthage bootstrap`，那一步沒在 runner 上驗證過。
- **TbCodeGenerater**：plugin 的 tool 在 Swift 6.3 是用 product 名去查的，那個 package
  的 product 叫 `tbCodeGenerater` 而 target 叫 `TbCodeGenerater`，所以整個 package
  在 runner 上建不起來（`no product named 'TbCodeGenerater'`）。改名之後要更新 CI 裡
  釘的 revision。

runner 是 Xcode 26（Swift 6.3），本機是 27（6.4），兩者對 build tool plugin 的差別：

- 6.3 用 product 名查 plugin 的 tool，6.4 接受 target 名。
- 6.3 不為 C 系 target 跑 build tool plugin，而且**回報成功**——沒有產物也沒有錯誤。
  6.4 會跑。fixture 的 ObjC target 因此不呼叫 plugin 產生的符號。
- 沒宣告 `platforms:` 的 package，6.3 用它支援的最舊 macOS 去建 macro，會和
  swift-syntax 宣告的版本打架。
