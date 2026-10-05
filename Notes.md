iina:

部分 dylib 不在 repo 裡，是 `other/download_libs.sh` 從 feed 抓的，而 feed 只留最新一版：
在那個 revision 上，它列的 71 個函式庫有 48 個已經不在，少掉的 symbol 會以
`cannot find 'MPV_FORMAT_FLAG' in scope` 這種形式出現在 Swift 編譯錯誤裡。
lane 把 feed 釘在檔案清單對得上該 revision 的版本（1.4.2），問題就消失了。

plist 的 `$(xxx)`：專案自己宣告的（pbxproj／xcconfig）與 Xcode 從 toolchain 帶入的
（`SDK_VERSION`、`XCODE_VERSION_*`、`SDK_NAME`、`PLATFORM_NAME`、`CONFIGURATION`）
都在 Swift 層取代掉了，剩下 `plisttool` 自己認的那幾個原樣交給 rules_apple。
只存在於 CI 環境或 secret 的設定仍然解不出來——那種 key 會被丟掉並具名回報。

CI（`.github/workflows/swift.yml`）目前沒跑的：

- **MacPass**：Carthage 依賴宣告的 deployment target 是 10.9–10.15，低於 Xcode 27
  接受的 12.0，`carthage bootstrap` 在第一個套件就失敗、`Carthage/Build` 從來沒被
  寫出來，app 因此什麼都連不到。lane 設定改不動這件事。

runner 是 Xcode 26（Swift 6.3），本機是 27（6.4），兩者對 build tool plugin 的差別：

- 6.3 用 product 名查 plugin 的 tool，6.4 接受 target 名。
- 6.3 不為 C 系 target 跑 build tool plugin，而且**回報成功**——沒有產物也沒有錯誤。
  6.4 會跑。Xcode 的 build system 兩邊都不跑，所以 iOS fixture 裡不放 plugin：
  macro 與 plugin 的樣本都在 `spm/`，那裡沒有 Xcode 專案。
- 沒宣告 `platforms:` 的 package，6.3 用它支援的最舊 macOS 去建 macro，會和
  swift-syntax 宣告的版本打架。
