# Roadmap: 自己產生 SwiftPM 的 BUILD

目前 SwiftPM 依賴是交給 `rules_swift_package_manager`（以下 rspm）處理的：
bazelize 只在 `MODULE.bazel` 裡宣告它、寫一份 `Package.swift`，剩下的 BUILD
由 rspm 在 fetch 階段產生在 external repo 裡。

這份文件描述「改成自己產生」之後，**輸出結構**長什麼樣，以及分階段的做法。
它只談產物形狀與責任邊界，不談實作細節。

---

## 為什麼要換

1. rspm 產出的 BUILD 有幾處對真實專案不夠用，我們現在用 4 個 vendored patch
   補（`Patches/rspm-*.patch` + `single_version_override`），還得帶版本守門。
2. 我們被釘在 rspm 1.15.0：≥1.16 會把每個 SwiftPM target 轉場到它自己宣告的
   platform floor，然後在依賴宣告更高版本時 analysis 失敗——Xcode 從不這樣做。
   平台語義本來就是 bazelize 的主場，自己產生就不會打架。
3. Xcode target 的 header／resource／plist 處理已經在 bazelize 裡了，package
   target 走同一套才會行為一致。
4. 產物變成簽入的檔案，出問題直接讀檔，不必追 repo rule。
5. 少一段 `bazel mod tidy` 補 `use_repo` 清單的流程。

代價：SwiftPM 的語義（traits、registry、binary target、plugin、macro）從此是
我們的責任。

---

## 現在的輸出（rspm 版，作為對照）

```
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

package 的 BUILD 不在這裡，而在 `external/rules_swift_package_manager++swift_deps+swiftpkg_<name>/`。

---

## 新的輸出（自己產生）

```
App/
├── MODULE.bazel              # 不再有 rspm；改成每個遠端 package 一個 repo rule
├── Package.swift             # 保留：仍用 SwiftPM 解析依賴圖
├── Package.resolved          # 保留：pin 的唯一來源
├── config.bazelrc
├── BUILD
├── Prebuilt/
├── Targets/<XcodeTarget>/    # 完全不變
└── Packages/                 # ★ 新增
    ├── BUILD                 # exports_files：給 repo rule 的 build_file 用
    └── <PackageName>/
        ├── BUILD.bazel       # 該 package 全部 target 的規則（我們產生）
        ├── Generated/
        │   ├── <Target>ResourceBundleAccessor.swift
        │   ├── <Target>.modulemap
        │   └── <Target>Defines.h
        └── Sources/          # 僅本地 package：指向 checkout 的 symlink 樹
```

`Patches/` 整組消失。

### 遠端 package 怎麼進來

`MODULE.bazel` 為每個遠端 package 產生一個 repo rule，revision 直接取自
`Package.resolved`，BUILD 用我們簽入的那份：

```python
git_repository(
    name = "swiftpkg_sfsafesymbols",
    remote = "https://github.com/SFSafeSymbols/SFSafeSymbols",
    commit = "…",                      # Package.resolved 的 revision
    build_file = "//Packages/SFSafeSymbols:BUILD.bazel",
)
```

這麼做的性質：

- **hermetic**：由 Bazel 抓、pin 到 revision，不依賴 `.build/checkouts`。
- **可讀**：BUILD 在我們的 repo 裡，不是產生在 external repo 裡。
- **仍要 `swift package resolve`**：但只在「依賴變動時」跑一次，用來更新
  `Package.resolved` 與讓 bazelize 讀到 manifest；build 本身不需要它。

### 本地 package 怎麼進來

本地 package（`.package(path: "../Packages/Account")`）和 Xcode target 同一個
workspace，走和 `Targets/` 相同的 symlink 樹，不需要 repo rule：

```
Packages/Account/
├── BUILD.bazel
├── Sources/            → symlink 到 ../../../Packages/Account/Sources
└── Generated/
```

label 形如 `//Packages/Account:Account`。

### Label 命名：facade（已實作）

所有 package product——遠端或本地——在 `Targets/*/BUILD` 裡都是同一個形狀：

| 對象 | 之前 | 現在 |
|---|---|---|
| 遠端 package 的 product | `@swiftpkg_sfsafesymbols//:SFSafeSymbols` | `//Packages/SFSafeSymbols:SFSafeSymbols` |
| 本地 package 的 product | `@swiftpkg_account//:Account` | `//Packages/Account:Account` |

`Packages/<Name>/BUILD` 是一層 alias，指向目前實作它的東西：

```python
alias(
    name = "SFSafeSymbols",
    actual = "@swiftpkg_sfsafesymbols//:SFSafeSymbols",
    visibility = ["//visibility:public"],
)
```

目錄名取人看得懂的 package 名（remote 用 URL 最後一段去掉 `.git`，local 用
目錄名），所以 `//Packages/GRMustache.swift:Mustache` 這種帶點的名字也成立。

意義：**換掉 SPM 實作只動 `Packages/` 底下的檔案**。階段 4 把 alias 換成規則
本體時，沒有任何 target 的 `deps` 需要改；中途要回退，把 alias 指回 rspm 即可。
測試也不再釘 rspm 的 repo 命名規則。

---

## SwiftPM 概念 → 產出的規則

| SwiftPM | 產出 |
|---|---|
| Swift target | `swift_library` |
| clang target（C/ObjC/C++） | `objc_library`，header／include 沿用 bazelize 現有邏輯 |
| 混合 target | `mixed_language_library` |
| system-library target | `cc_library` + 我們產生的 modulemap |
| binary target（xcframework） | `apple_dynamic_xcframework_import` / `apple_static_xcframework_import` |
| binary target（本地 archive） | 先解壓，再同上 |
| `.process` / `.copy` resources | `apple_resource_bundle` + `Generated/<Target>ResourceBundleAccessor.swift` |
| auto-discovered resources（xib／xcassets／metal／xcstrings） | 同上，`.metal` 連同該 target 的 header 一起進 resource group |
| `defines` | `-D`（值不安全時走 `Generated/<Target>Defines.h`，與 Xcode target 同策略） |
| `headerSearchPath` | `includes` |
| `linkedLibrary` / `linkedFramework` | `linkopts` / `sdk_frameworks` |
| `swiftLanguageMode` | `-swift-version` |
| `enableUpcomingFeature` / `enableExperimentalFeature` | rules_swift 的 `features` |
| `defaultIsolation` | `-default-isolation <value>` |
| `unsafeFlags` | `copts` |
| build tool plugin（SwiftLint 等） | 階段 3；先跳過並警告 |
| macro / compiler plugin | 階段 3；`swift_compiler_plugin` |
| traits（SE-0450） | 依 enabled traits 展開成 `-D` 與條件依賴 |

---

## 階段 0 的結果（已量測）

語料：12 個 app 目前展開出的 **119 個 package／208 個非測試 target**（讀 rspm 產生
在 external repo 裡的 `dump.json` 與 `desc.json`；`swift package dump-package`
與 `describe` 的輸出）。

### target 種類

| module type | 數量 |
|---|---|
| SwiftTarget | 170 |
| ClangTarget | 50 |
| BinaryTarget | 2 |
| SystemLibraryTarget | 2 |
| PluginTarget | 1 |

沒有 macro target，也沒有混合語言 target（SwiftPM 本來就不允許）。

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
- **plugin 使用**：9 個 package，**全部是 SwiftLint**
  （`SwiftLintPlugin` 5 個、`SwiftLintPlugins` 4 個）——只做 lint，不產生原始碼。
- **plugin target**：只有 1 個，swift-argument-parser 的 `GenerateManual`，
  語料裡沒有人消費它。
- **binary target**：2 個（Sparkle 的遠端 xcframework、CodeEditLanguages 的本地
  `.zip`）。

### 這代表什麼

把「lint-only 的 build tool plugin 略過（印警告）」和「不產生也不輸出沒人消費的
plugin target／product」當成規則，語料裡**119 個 package 全部落在階段 1–2**：

| 階段支援的範圍 | 覆蓋 package |
|---|---|
| 純 Swift library、無 resource | 58 |
| ＋ clang／resources／binary／system | 61（累計 119） |
| macro、會產生原始碼的 plugin | 0（語料裡沒有） |

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

## 分階段與通過條件

每一階段的通過條件都一樣：**12 個 app 至少維持現狀**（7 個綠的仍綠、blocked 的
理由不變），加上 114 單元測試與 iOS fixture。

| 階段 | 範圍 | 目標 |
|---|---|---|
| 0 ✅ | 量測語料 | 見上 |
| 0.5 ✅ | `//Packages` facade（alias 指向 rspm） | 所有 app，label 形狀定案 |
| 1 | 純 Swift library target、`swiftLanguageMode`／`define`／upcoming・experimental feature／`strictMemorySafety`／`defaultIsolation`／`unsafeFlags`；lint-only plugin 略過並警告；plugin target 不產生。flag 切換，預設仍 rspm | 58 個 package 能單獨建起來 |
| 2 | clang target（`headerSearchPath`／`publicHeadersPath`／明列 `sources`／`exclude`）、resources + `Bundle.module` accessor、binary target（遠端 xcframework 與本地 archive）、system library | 全部 12 個 app 至少維持現狀 |
| 3 | macro／會產生原始碼的 build tool plugin | 語料外的需求出現時再做 |
| 4 | 預設切換，移除 rspm 依賴、`Patches/` 與版本守門 | 全部 |

階段 1–3 期間 rspm 與自製產生器**不混用**：同一個 workspace 只走其中一條，由
flag 決定；混用會產生兩張依賴圖。

---

## 待決事項

1. 遠端 package 用 `git_repository`（pin revision）還是 `http_archive`
   （pin tarball + sha256）？後者快、可快取，但 `Package.resolved` 只給 revision，
   要自己組 tarball URL 並算 checksum。
2. registry package（`.package(id:)`）階段幾支援？目前語料沒有。
3. `Package.swift` 是否還需要出現在產物裡？只有 `swift package resolve` 需要它，
   可以改成只在更新 pin 時才產生。
4. 階段 1–4 期間，上游 rspm PR 還要不要送？（我建議要，patch 很小，對別人也有用）
