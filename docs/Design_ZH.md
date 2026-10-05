# Bazelize

---

## `Bazelize` 的目標

 1. 在儘量不影響現有 `Xcode` 專案的情況下，達成轉移到 `bazel` 的過程。
     * 見 [Ref](#Ref)
 2. 將 `xxx.xcodeproj` 以及其相依套件，如 `spm`，轉移至 `bazel`(`pod` 目前尚未支援)。

----

### 解析 `xcodeproj`

我們能透過 [XcodeProj](https://github.com/tuist/XcodeProj) 去解析，得到其 `Xcode Target` 設定，最後填入到對應的 `rules`。

(後續實作方向: `Xcode Target` -> 中間層 -> generate code)

> `Xcode Target` 將視為 [Bazel Packages](https://docs.bazel.build/versions/4.2.1/build-ref.html#packages)

見 [`Xcode Target` setting](#Xcode-Target-setting)

---

## 套件管理

見 [Dependecy](Dependecy_ZH.md)

---

## Bazelize 設計

----

### xxx_library

首先我先來談談程式碼部分，我們的程式碼會套用在特殊的 rule 上，如 `xxx_library`。

(`xxx_library` 一個 rule 只能處理一種語言，所以我們由原始碼的語言決定要產生哪個 rule)

 * 只有 Swift -> `swift_library`
 * 只有 C 家族(`.c`/`.m`/`.mm`/`.cc`) -> `objc_library`
 * 兩者都有 -> `mixed_language_library`(來自 `rules_swift`)

> 混合語言的 target 中，Objective-C 端透過 generated header `${module_name}-Swift.h` 看到 Swift，
> Swift 端則透過 bridging header / module map 看到 Objective-C。


### `Xcode Target` type

我們先從 `Xcode Target` type 暸解起，初步我們會先實作較為常見的幾種 type。

見 [PBXProductType][product_type]

### 辨識 `Xcode Target` type

主要由 [PBXProductType][product_type] 以及 [XCConfigurationList][config_list] 作為判斷標準。


### `Xcode Target` + `Naming Rule`

`BUILD` file 主要由兩種 rule 組成，`xxx_library` and `main rule`。

假設 Target2 是 `iOS Framework` 且用 objc 實作。


那 Target2 的 `xxx_library` 就是 `objc_library`，且其 name 為 `TargetName + _xxx`，也就是 `Target2_objc`。

```bazel
objc_library(
    name = "Target2_objc",
)
```

接著來說明 `main rule`，我們得知 Target2 為 `iOS Framework`，我們透過對應關係將其對應到 rule `ios_framework`，且其 name 為 `TargetName`，也就是 `Target2`。

```bazel
ios_framework(
    name = "Target2",
)
```

最後，對於 `xxx_library` 我們並不在乎他是用什麼語言實作，只期望有 library 可以使用。於是再將 `Target2_objc` 命名為 `Target2_library`。

```bazel
alias(
    name = "Target2_library",
    actual = "Target2_objc",
    visibility = ["//visibility:public"],
)
```

----

#### Example

舉例來說， 

 * Target1: 
     * iOS Application
     * pure swift
 * Target2:
     * iOS Framework
     * objc

##### Target2

目錄結構：

```bash
└── Targets
    └── Target2
        ├── BUILD
        └── xxx.m
```

```bazel
# Targets/Target2/BUILD
objc_library(
    name = "Target2_objc", # Target2 + _objc
    src = [
        "xxx.m",
    ]
)
alias(
    name = "Target2_library",
    actual = "Target2_objc",
    visibility = ["//visibility:public"],
)

ios_framework(
    name = "Target2",
    deps = [
        ":Target2_library",
    ]
)
```

##### Target1

目錄結構：

```bash
└── Targets
    └── Target1
        ├── BUILD
        └── xxx.swift
```


```bazel
# Targets/Target1/BUILD
swift_library(
    name = "Target1_swift",
    srcs = [
        "xxx.swift",
    ],
    deps = [
        "//Targets/Target2:Target2_library"
    ]
)

alias(
    name = "Target1_library",
    actual = "Target1_swift",
    visibility = ["//visibility:public"],
)

ios_application(
    name = "Target1",
    deps = [
        # ":Target_swift",
        ":Target1_library",
    ],
    frameworks = [
        "//Targets/Target2:Target2",
    ]
)
```

----

## 預期專案結構

產生出來的檔案全部寫在 `--output` 指定的目錄底下，輸入的專案目錄不會被修改。

```bash
<output>
├── MODULE.bazel            # bzlmod，非 WORKSPACE
├── BUILD                   # mode flag / config_setting / lint / format / plugins / xcodeproj
├── .bazelrc                # 只負責 import 下面三個
├── config.bazelrc          # Debug/Release ... 等 config
├── traits.bazelrc          # SwiftPM trait
├── languages.bazelrc       # 語言相關 flag
├── .bazelignore
├── .bazelversion
├── lint.sh
├── format.sh
├── plugins.sh              # bazel run //:plugins 執行的 script
├── plugin-host.swift       # bazelize 自己實作的 build tool plugin host
├── plugin-plan.json
├── tools
│   ├── BUILD
│   ├── bazel
│   ├── list-config.sh
│   ├── list-trait.sh
│   └── list-language.sh
├── Prebuilt                # .framework/.xcframework/靜態動態 library import
│   └── BUILD
├── Targets                 # 只有在輸入是 xcodeproj 時才會有
│   ├── Target1
│   │   ├── BUILD
│   │   ├── Sources
│   │   └── Generated
│   └── Target2
│       ├── BUILD
│       ├── Sources
│       └── Generated
├── Packages                # SwiftPM
│   ├── BUILD
│   └── <Package>
│       ├── BUILD
│       ├── Sources
│       │   └── <Target>
│       └── Generated
├── Package.swift           # 合成的 manifest，不是輸入的那一份
└── Package.resolved        # 由輸入保留下來
```

---

## `Xcode Target` setting

 * [x] type(application/framework/...)
 * [x] setting
   * [x] default setting
   * [x] target setting
 * [x] config(Debug/Release/...)
   * 以 `//:mode` `string_flag` 加上 `config_setting` 實作，差異部分寫成 `select`。
 * [x] compile opts
     * [x] swift
     * [x] c
     * [x] link
 * [x] plist
     * [x] plist file
     * [x] plist gen
 * [x] xcconfig
   * `XCConfigurationList` 載入時會解析 `.xcconfig`(含 `#include`)並與 inline setting 合併。
 * [x] srcs(`sourcesBuildPhase`)
     * [x] .swift -> `swift_library`
     * [x] .m/.c/.mm/.cc -> `objc_library`
     * [x] .swift + C 家族 -> `mixed_language_library`
     * SwiftPM 的 system library 則是 `cc_library`。

----

### plist file

----

### plist gen

GENERATE_INFOPLIST_FILE

prefix `INFOPLIST_KEY_`
`INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad`
`UISupportedInterfaceOrientations_iPad`

---

## 建議事項

 * Xcode Target -> 中間層實作

### 多語言 Target

同時含有 Swift 與 C 家族原始碼的 target，會產生 `rules_swift` 的 `mixed_language_library`，
命名規則維持 `TargetName + _mixed`，再由 `alias` `TargetName + _library` 對外。

```bazel
mixed_language_library(
    name = "RxSwift_mixed",
    clang_srcs = [...],
    swift_srcs = [...],
)
alias(
    name = "RxSwift_library",
    actual = "RxSwift_mixed",
    visibility = ["//visibility:public"],
)
```

### 支援 plugin

見 [Building and loading dynamic libraries at runtime in Swift](https://theswiftdev.com/building-and-loading-dynamic-libraries-at-runtime-in-swift/)

#### plugin interface

目前實際在用的是 builtin plugin(`Sources/BazelizeKit/Plugin/`)：
`PluginBuildifier`、`PluginGitRepository`、`PluginSwiftPM`、`PluginApple`、`PluginSwift`、
`PluginXcodeProj`、`PluginPlistFragment`、`PluginLinker`，由 `Kit.builtinPlugins` 註冊。
plugin 可以補 `MODULE.bazel` 的 dependency、per-target 的 deps，以及產生結束後的 tip。

#### plugin loader

外部動態載入的 plugin(`Sources/PluginLoader/`)目前是停用狀態：`Kit` 中的 `loadPlugins` 被註解掉，
`plugins` 永遠是空陣列，所以只有 builtin plugin 會生效。

---

## Ref

 * [将大型 iOS 应用迁移至 Bazel](https://www.youtube.com/watch?v=PPgiv7GLH6Y&ab_channel=GoogleOpenSource)
 * [iOS and Bazel at Reddit: A Journey](https://www.reddit.com/r/RedditEng/comments/syz5dw/ios_and_bazel_at_reddit_a_journey)
 * [BazelCon 2019 Day 1: Porting iOS Apps to Bazel + Q&A](https://www.youtube.com/watch?v=gVdkJu3QRA4)
 * [Keith Smiley of Lyft on How to Scale Code with Bazel](https://semaphoreci.com/blog/keith-smiley-bazel)
 * [Improving Build Performance of LINE for iOS with Bazel](https://engineering.linecorp.com/en/blog/improving-build-performance-line-ios-bazel)


[product_type]: https://github.com/tuist/XcodeProj/blob/main/Sources/XcodeProj/Objects/Targets/PBXProductType.swift
[config_list]: https://github.com/tuist/XcodeProj/blob/main/Sources/XcodeProj/Objects/Configuration/XCConfigurationList.swift
