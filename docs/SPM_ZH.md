# SwiftPM

## 目標

由 bazelize 自己產生專案裡 Swift package 的 Bazel 規則。以前是在 `MODULE.bazel`
裡宣告 `rules_swift_package_manager`（以下 rspm）、寫一份合成的 `Package.swift`，
package 的 BUILD 由 rspm 在 fetch 階段產生在 external repo 裡。

這份文件描述**輸出結構**、SwiftPM 概念到規則的對應，以及這次替換的分階段做法。
它只談產物形狀與責任邊界，不談實作細節。

## 為什麼要換

1. rspm 產出的 BUILD 有幾處對真實專案不夠用，當時用 4 個 vendored patch 補
   （`Patches/rspm-*.patch` + `single_version_override`），還得帶版本守門。
2. 我們被釘在 rspm 1.15.0：≥1.16 會把每個 SwiftPM target 轉場到它自己宣告的
   platform floor，然後在依賴宣告更高版本時 analysis 失敗——Xcode 從不這樣做。
   平台語義本來就是 bazelize 的主場，自己產生就不會打架。
3. Xcode target 的 header／resource／plist 處理已經在 bazelize 裡了，package
   target 走同一套才會行為一致。
4. 產物是簽入的檔案，出問題直接讀檔，不必追 repo rule。
5. 少一段 `bazel mod tidy` 補 `use_repo` 清單的流程。

代價：SwiftPM 的語義（traits、registry、binary target、plugin、macro）從此是
我們的責任；還沒做到的那一項——package 自己的 platform floor——寫在文件最後。

## 以前的輸出（rspm 版，作為對照）

```text
App/
├── MODULE.bazel              # bazel_dep(rules_swift_package_manager)
│                             # + swift_deps.from_package + use_repo(...)
│                             # + single_version_override(patches = …)
├── Patches/                  # vendored rspm patch（版本守門）
│   ├── BUILD
│   └── rspm-*.patch
├── Package.swift             # 給 rspm 讀的合成 manifest
├── Package.resolved          # 由 Xcode 的 Package.resolved 播種
├── config.bazelrc
├── BUILD
├── Prebuilt/                 # 專案自帶的 .framework/.a/.dylib（symlink）
└── Targets/<XcodeTarget>/
    ├── BUILD
    ├── Sources/              # 指向原始碼的 symlink 樹
    ├── Headers/<Module>/     # 扁平化 header 樹
    ├── Generated/            # BazelizeDefines.h、entitlements、asset symbols
    └── CopyFiles/<dest>/     # copy phase 目的地
```

package 的 BUILD 不在那裡，而在
`external/rules_swift_package_manager++swift_deps+swiftpkg_<name>/`。

## 輸出

```text
App/
├── MODULE.bazel              # 不再有 rspm
├── Package.swift             # 保留：仍用 SwiftPM 解析依賴圖
├── Package.resolved          # 保留：pin 的唯一來源
├── config.bazelrc
├── BUILD
├── Prebuilt/
├── Targets/<XcodeTarget>/    # 完全不變
└── Packages/                 # ★ 新增
    └── <PackageName>/
        ├── BUILD             # 該 package 全部 target 的規則（我們產生）
        ├── Generated/        # resource bundle accessor、module map、plist
        ├── Sources/<Target>  # 指向該 target 原始碼的 symlink
        └── Artifacts/<Target>/<Name>.xcframework   # binary target
```

`Patches/` 整組消失。

### package 的原始碼怎麼進來

每個 package——遠端或本地——都是這個 workspace 裡的一個目錄，裡面放我們產生的
`BUILD`，以及每個 target 一條指向 SwiftPM 既有原始碼的 symlink：

```text
Packages/SFSafeSymbols/
├── BUILD
└── Sources/
    └── SFSafeSymbols -> <workspace>/.build/checkouts/SFSafeSymbols/Sources/SFSafeSymbols
```

所以 target 的原始碼就是 `Sources/<Target>/**/*.swift`。本地 package 指向它
manifest 所在的位置，就地讀取。

這個選擇的性質：

- 和 `Targets/` 同一個形狀：symlink 樹加上旁邊產生的 `BUILD`，只有一套機制。
- 沒有 external repository，所以沒有 `use_repo` 清單，也不需要 `bazel mod tidy`。
- 解析仍然是 SwiftPM 的事：bazelize 跑 `swift package resolve`，再用
  `swift package dump-package` 讀每個 checkout 的 manifest——離線、而且橫跨
  依賴圖裡所有 tools version。
- 一個 target 一條 symlink（而不是整包 checkout 一條），checkout 其餘部分就不會
  進到 build 裡——package 可能自己帶 `BUILD` 檔。

另一個選項是每個遠端 package 產生一個 `git_repository`，用 `Package.resolved`
的 revision 釘住：那是 hermetic 的，但又把 external repo 帶回來，還會重抓一份
Bazel 手上已經有的原始碼。

### Label 命名

所有 package product——遠端或本地——在 `Targets/*/BUILD` 裡都是同一個形狀：

| 對象 | 之前 | 現在 |
|---|---|---|
| 遠端 package 的 product | `@swiftpkg_sfsafesymbols//:SFSafeSymbols` | `//Packages/SFSafeSymbols:SFSafeSymbols` |
| 本地 package 的 product | `@swiftpkg_account//:Account` | `//Packages/Account:Account` |

目錄名取人看得懂的 package 名（remote 用 URL 最後一段去掉 `.git`，local 用
目錄名），所以 `//Packages/GRMustache.swift:Mustache` 這種帶點的名字也成立。

不論規則是誰產生的，product 就是這個 label——這也是這次替換只動 `Packages/` 的
原因：label 形狀先落地（當時是指向 rspm 的 alias），之後換成規則本體，沒有任何
target 的 `deps` 需要改。測試也不釘 package 的規則是怎麼產生的。

## SwiftPM 概念 → 產出的規則

| SwiftPM | 產出 |
|---|---|
| Swift target | `swift_library` |
| clang target（C/ObjC/C++） | `objc_library` + `swift_interop_hint`，package 沒帶 module map 時我們產生一份 |
| system-library target | `cc_library` + `swift_interop_hint`，用 package 自己帶的 module map |
| binary target（xcframework） | `apple_dynamic_xcframework_import` / `apple_static_xcframework_import` |
| binary target（本地 archive） | 先解壓，再同上 |
| library product，單一 target | `alias` |
| library product，多個 target | `swift_library_group` |
| `.process` / `.copy` resources | `apple_resource_bundle` + `Generated/<Target>ResourceBundleAccessor.swift` |
| auto-discovered resources（xib／xcassets／metal／xcstrings／`.lproj`） | 同上；有 `.metal` 時該 target 的 header 也一起進 resource group，因為 bundler 會把它們當 Metal header 編 |
| `defines` | `-D` flag，不用 `defines` 屬性——那會往每個下游傳 |
| `headerSearchPath` | `includes`，而且該目錄被 `exclude` 丟掉時 header 仍然留作輸入 |
| `linkedLibrary` / `linkedFramework` | `linkopts` |
| `swiftLanguageMode` | `-swift-version` |
| `enableUpcomingFeature` / `enableExperimentalFeature` | `-enable-upcoming-feature` / `-enable-experimental-feature` |
| `defaultIsolation` | `-default-isolation <value>` |
| `interoperabilityMode` | `-cxx-interoperability-mode=<value>` |
| `strictMemorySafety` | `-strict-memory-safety` |
| `unsafeFlags` | `copts` |
| build tool plugin（SwiftLint 等） | 不執行；結束時把該 plugin 的名字講出來 |
| macro target | `swift_compiler_plugin`，並在宣告該 macro 的 target 上加 `plugins` |
| traits（SE-0450） | 依 enabled traits 展開成 `-D` 與條件依賴 |

每個產生的 `swift_library` 都對齊兩個 SwiftPM 行為：`alwayslink`，因為 SwiftPM
一律整份連結 package library；還有 `always_include_developer_search_paths`，
`RxTest` 這種測試輔助 library 就是靠它找到 XCTest。每個產生的規則另外都標
`manual`：package target 是透過會轉場到某個平台的 bundle 規則建起來的，wildcard
pattern 不該把 iOS-only 的 package 拿去編 host。

C 系 target 的公開 header 會連結到一個產生出來的 interface 目錄，module map 就放在
同一層，而那個目錄就是 header search path。clang 只在「找到 header 的那個目錄」找
`module.modulemap`，所以 map 必須和 header 同層，而 checkout 不是我們能寫的地方。

module map 決定 C 系模組叫什麼。沒有它，模組名會由 label 推導出來，原始碼就沒辦法
用自己寫的名字 import；package 自己帶的 map 優先，因為那是它想提供的介面。用 header
search path 找得到，是每個消費端都能解到模組的原因——Swift 或 C 系、同一個 package、
別的 package、或 Xcode target 都一樣，因為只有 Swift 端的模組是規則給的。

package 的原始碼是一個 target 一條 symlink，checkout 其餘部分不會進 build；
`.bazelignore` 也把 SwiftPM 的工作目錄排除在外。兩件事同一個理由：package 可能
自己帶 `BUILD` 檔，Bazel 會把它當成這個 workspace 的 package 去載。

package 自己宣告的 platform floor 是**故意忽略**的——逐 package 遵守它，正是把
我們釘在 rspm 1.15.0 的那個行為。代價寫在下面階段 2 的結果裡。

## 階段 0 的結果（已量測）

語料：12 個 app 目前展開出的 **119 個 package／208 個非測試 target**（讀 rspm
產生在 external repo 裡的 `dump.json` 與 `desc.json`，也就是
`swift package dump-package` 與 `describe` 的輸出）。

### target 種類

| module type | 數量 |
|---|---|
| SwiftTarget | 170 |
| ClangTarget | 50 |
| BinaryTarget | 2 |
| SystemLibraryTarget | 2 |
| PluginTarget | 1 |

沒有 macro target，也沒有混合語言 target（SwiftPM 本來就不允許）。iOS fixture 自己
補了一個 macro，所以 macro 的規則是用「建起來並驗證展開結果」來檢查，不是靠讀產出。

### build settings（用到的 target 數／package 數）

| setting | targets | packages |
|---|---|---|
| `swift.enableUpcomingFeature` | 116 | 5 |
| `c.headerSearchPath` | 44 | 28 |
| `swift.strictMemorySafety` | 23 | 4 |
| `swift.enableExperimentalFeature` | 21 | 14 |
| `swift.define` | 14 | 4 |
| `swift.swiftLanguageMode` | 13 | 13 |
| `swift.defaultIsolation` | 10 | 10 |
| `c.define` | 6 | 3 |
| `linker.linkedLibrary` | 1 | 1 |
| `linker.linkedFramework` | 1 | 1 |
| `swift.unsafeFlags` | 1 | 1 |

### 其他形狀

- **resources**：32 個 package（`.copy` 37 處、`.process` 4 處）→ 需要 resource
  bundle 與 `Bundle.module` accessor。
- **manifest 形狀**：明列 `sources` 30 個 target、`exclude` 32、
  `publicHeadersPath` 33 → clang target 的檔案收集不能只靠慣例。
- **tools-version** 從 4.2 到 6.3 都有（最多的是 5.3，30 個）。
- **plugin 使用**：9 個 package，**全部是 SwiftLint**（`SwiftLintPlugin` 5 個、
  `SwiftLintPlugins` 4 個）——只做 lint，不產生原始碼。
- **plugin target**：只有 1 個，swift-argument-parser 的 `GenerateManual`，
  語料裡沒有人消費它。
- **binary target**：2 個（Sparkle 的遠端 xcframework、CodeEditLanguages 的本地
  `.zip`）。

### 這代表什麼

把「lint-only 的 build tool plugin 略過（印警告）」和「不產生沒人消費的 plugin
target」當成規則，語料裡**119 個 package 全部落在階段 1–2**：

| 階段支援的範圍 | 覆蓋 package |
|---|---|
| 純 Swift library、無 resource | 58 |
| ＋ clang／resources／binary／system | 61（累計 119） |
| macro、會產生原始碼的 plugin | 0（語料裡沒有；fixture 自己有一個 macro） |

每個 app 需要的最低階段（用各 workspace 的 `Package.resolved` 展開）：

| app | pins | 需要到 |
|---|---|---|
| Rectangle | 2 | 階段 2 |
| SwiftBar | 5 | 階段 2 |
| MonitorControl | 6 | 階段 2 |
| iina | 4 | 階段 2 |
| IceCubesApp | 20 | 階段 2 |
| VirtualBuddy | 6 | 階段 2（只差 argument-parser 的 plugin target 要略過） |
| UTM | 15 | 階段 2（同上） |
| PlayCover | 8 | 階段 2（同上） |
| CotEditor | 29 | 階段 2（＋SwiftLint plugin 略過） |
| CodeEdit | 34 | 階段 2（＋SwiftLint plugin 略過） |

也就是說：**macro 與真 plugin 可以整段延後**，階段 2 做完就能覆蓋全部語料。

## 階段 1 的結果（已量測）

這個階段只產生純 Swift 的 package target，由一個 flag 切換，預設仍是 rspm。還不
支援的種類會略過
並印警告，依賴它的 target 也一起略過：一個少了它要連結的 target 的 library，
比根本不存在更糟。

7 個原本綠燈的 macOS app 跑 `bazel build //...`：

| app | 結果 | 卡住的 target 種類 |
|---|---|---|
| stats | 建得起來 | — |
| MacPass | 建得起來 | — |
| MonitorControl | 需要階段 2 | Sparkle，binary target |
| SwiftBar | 需要階段 2 | Sparkle，binary target |
| Rectangle | 需要階段 2 | MASShortcut，clang target |
| iina | 需要階段 2 | GRMustache.swift 的 `GRMustacheKeyAccess`，clang target |
| VirtualBuddy | 需要階段 2 | BuddyKit，clang target |

每個失敗都是「少了一種 target 種類」，不是規則產錯：唯一解不到的 label 就是
那些指向被略過 target 的 product。

## 階段 2 的結果（已量測）

語料裡 package 會用到的每一種 target 都會產生了：C 系、帶 resource、binary、
system library，加上原本的 Swift。

跑 `bazel build //...`，再啟動 app：

| app | 結果 |
|---|---|
| MonitorControl、SwiftBar、stats、Rectangle、MacPass、iina、VirtualBuddy | 建得起來也跑得起來 |
| CodeEdit | package 全部建得起來；app 自己的原始碼被 Swift 6.4 擋下 |
| CotEditor | package 全部建得起來；app 自己的原始碼被 Swift 6.4 擋下 |
| IceCubesApp | package 全部建得起來；app 自己的原始碼和 iOS 27 SDK 撞名（`SwiftUI.Document`） |
| UTM | package 都建得起來；app 本身需要預先 build 的 sysroot，另有一處原始碼靠 Xcode 的 project headermap 用檔名 include header |
| PlayCover | `swift package resolve` 在 package 自己的 manifest 上就失敗 |

沒建起來的四個，失敗點都不在我們產生的東西裡：三個是自己的原始碼碰上更新的
compiler 與 SDK，一個是上游 manifest。

### 平台版本

package 會宣告自己支援的平台版本，SwiftPM 編它的 target 時取「自己宣告的」和
「使用端的」之中較高的那個。bazelize 一律用專案的 deployment target 編所有 package
target：版本存在於「拉它進來的 bundle 規則」的 platform transition 裡，library
規則本身沒有版本這個屬性。逐 target 遵守它，正是 rspm 依賴當時被釘在 1.15.0 的
原因——之後的版本會把每個 target 轉場到它自己的 floor，然後在依賴宣告更高版本時
analysis 失敗。

package 要求的版本還是會算出來，算法和 SwiftPM 一樣：

1. manifest 的 `platforms:` 對該平台宣告的值；
2. 沒宣告就用 SwiftPM 建該平台的最低版本——macOS 12、iOS 與 tvOS 15、watchOS 9、
   visionOS 1、Mac Catalyst 15、DriverKit 21；
3. 專案有建該平台但沒寫版本時，問已安裝的 SDK：它附的 `XCTest` 的 deployment
   target，就是 SwiftPM 問同一個問題的方式。

算出來的值會和「專案自己的 target 之中最低的 deployment target」比。package 要求
更高時，會在執行結束時把兩個版本一起講出來——不然失敗會以「別人原始碼深處的
availability 錯誤」的形式出現。

「用 package 要求的版本去編它」並不是解法，因為 SwiftPM 自己也不這樣做——它直接拒絕
這張圖：

```text
error: The package product 'Dep-product' requires minimum platform version 14.0
for the macOS platform, but this target supports 12.0
```

為較新平台建出來的模組，較舊平台不能 import（Swift 也是直接報錯），所以唯一的解法
是專案拉高自己的 deployment target，或 package 降低它宣告的版本。把「是哪個 package、
哪兩個版本」講出來，就是這件事的全部。

同一個實驗也顯示 SwiftPM 比較之前會把**兩邊**都拉到它自己的最低版本（上面那個專案
宣告 macOS 11，錯誤訊息裡是 12），所以「沒宣告」的 package 永遠不會是圖被拒絕的原因。
因此這裡只回報 manifest 明確宣告的版本。

## 分階段與通過條件

每一階段的通過條件都一樣：**12 個 app 至少維持現狀**（7 個綠的仍綠、blocked 的
理由不變），加上 114 單元測試與 iOS fixture。

| 階段 | 範圍 | 目標 |
|---|---|---|
| 0 ✅ | 量測語料 | 見上 |
| 0.5 ✅ | `//Packages` facade（alias 指向 rspm） | 所有 app，label 形狀定案 |
| 1 ✅ | 純 Swift library target、`swiftLanguageMode`／`define`／upcoming・experimental feature／`strictMemorySafety`／`defaultIsolation`／`interoperabilityMode`／`unsafeFlags`；不支援的種類連同它的下游一起略過並警告；由一個 flag 切換，預設仍 rspm | 58 個 package 能單獨建起來 |
| 2 ✅ | clang target（`headerSearchPath`／`publicHeadersPath`／明列 `sources`／`exclude`／module map）、resources + `Bundle.module` accessor、binary target（遠端 xcframework 與本地 archive）、system library | 7 個綠燈 app 建得起來也跑得起來；另外五個的 package 全部建得起來 |
| 3 | macro target ✅；逐 target 的平台版本 ✅（不需要做——SwiftPM 自己就會拒絕這種圖，所以回報就是答案）；會產生原始碼的 build tool plugin 還沒做 | 語料外的需求出現時再做 |
| 4 ✅ | rspm 依賴、`Patches/`、版本守門與模式 flag 全部移除 | 7 個綠燈 app 建得起來也跑得起來 |

階段 4 是把另一條路整個移除，而不是留一個 flag：兩條路就是兩張依賴圖，而語料裡
每個 app 用自製產生器的結果都不比 rspm 差。

## 待決事項

1. `Package.swift` 是否還需要出現在產物裡？只有 `swift package resolve` 需要它，
   可以改成只在更新 pin 時才產生。
2. registry package（`.package(id:)`）階段幾支援？目前語料沒有。
3. 上游 rspm PR 還要不要送？那 4 個 patch 很小，對還在用 rspm 的人也有用。
