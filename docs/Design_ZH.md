# Bazelize

---

## `Bazelize` 的目標

 1. 在儘量不影響現有 `XCode` 專案的情況下，達成轉移到 `bazel` 的過程。
     * 見 [将大型 iOS 应用迁移至 Bazel][Ref1]
 2. 將 `xxx.xcodeproj` 以及其相依套件，如 `pod`, `spm` ...，轉移至 `bazel`。

----

### 解析 `xcodeproj`

我們能透過 [XcodeProj](https://github.com/tuist/XcodeProj) 去解析，得到其 `XCode Target` 設定，最後填入到對應的 `rules`。

(後續實作方向: `XCode Target` -> 中間層 -> generate code)

> `XCode Target` 將視為 [Bazel Packages](https://docs.bazel.build/versions/4.2.1/build-ref.html#packages)

見 [`XCode Target` setting](#XCode-Target-setting)

---

## 套件管理

見 [Dependecy](Dependecy_ZH.md)

---

## Bazelize 設計

----

### xxx_library

首先我先來談談程式碼部分，我們的程式碼會套用在特殊的 rule 上，如 `xxx_library`。

(目前以作者所知 `xxx_library` 只能套用在同一種語言)

我們目前會著重在 `swift_library` 及 `objc_library` 的實作。

所幸，`XCode Target` 似乎同時只支援一種語言。

> 例外: application 可透過 `bridge-header` 或 generated header `RxSwift-Swift.h`，


### `XCode Target` type

我們先從 `XCode Target` type 暸解起，初步我們會先實作較為常見的幾種 type。

```swift
public enum PBXProductType: String, Decodable {
    case none = ""
    case application = "com.apple.product-type.application"
    case framework = "com.apple.product-type.framework"
    case staticFramework = "com.apple.product-type.framework.static"
    case xcFramework = "com.apple.product-type.xcframework"
    case dynamicLibrary = "com.apple.product-type.library.dynamic"
    case staticLibrary = "com.apple.product-type.library.static"
    case bundle = "com.apple.product-type.bundle"
    case unitTestBundle = "com.apple.product-type.bundle.unit-test"
    case uiTestBundle = "com.apple.product-type.bundle.ui-testing"
    case appExtension = "com.apple.product-type.app-extension"
    case commandLineTool = "com.apple.product-type.tool"
    case watchApp = "com.apple.product-type.application.watchapp"
    case watch2App = "com.apple.product-type.application.watchapp2"
    case watch2AppContainer = "com.apple.product-type.application.watchapp2-container"
    case watchExtension = "com.apple.product-type.watchkit-extension"
    case watch2Extension = "com.apple.product-type.watchkit2-extension"
    case tvExtension = "com.apple.product-type.tv-app-extension"
    case messagesApplication = "com.apple.product-type.application.messages"
    case messagesExtension = "com.apple.product-type.app-extension.messages"
    case stickerPack = "com.apple.product-type.app-extension.messages-sticker-pack"
    case xpcService = "com.apple.product-type.xpc-service"
    case ocUnitTestBundle = "com.apple.product-type.bundle.ocunit-test"
    case xcodeExtension = "com.apple.product-type.xcode-extension"
    case instrumentsPackage = "com.apple.product-type.instruments-package"
    case intentsServiceExtension = "com.apple.product-type.app-extension.intents-service"
    case onDemandInstallCapableApplication = "com.apple.product-type.application.on-demand-install-capable"
    case metalLibrary = "com.apple.product-type.metal-library"
    case driverExtension = "com.apple.product-type.driver-extension"
    case systemExtension = "com.apple.product-type.system-extension"
}
```

### `XCode Target` `iOS Application`

如何得知 `Target` 是 `iOS Application`，可以從 `type` 得知其為 `.application`

```swift
target.type == .application
```

接著預期可以從 Target Setting 得知為 iOS，期望是 `target.setting[sdk] == "iphoneos"`

```swift
target.setting[sdk] == "iphoneos"
```

實際上是：

```swift
let config = "Debug"
(target.setting[config][sdk] ?? defaultSetting[config][sdk]) == "iphoneos"
```

### `XCode Target` + `Naming Rule`

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

```bash=
└── Target2
    ├── BUILD
    └── xxx.m
```

```bazel=
# Target2/BUILD
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

```bash=
└── Target1
    ├── BUILD
    └── xxx.swift
```


```bazel=
# Target1/BUILD
swift_library(
    name = "Target1_swift",
    srcs = [
        "xxx.swift",
    ],
    deps = [
        "//Target2:Target2_library"
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
        "//Target2:Target2",
    ]
)
```

----

## 預期專案結構

```shell=
├── xxx.xcodeproj
├── xxx.xcworkspace
├── # BUILD?
├── WORKSPACE
├── Pods.WORKSPACE # PodToBUILD
├── Podfile
├── Podfile.lock
├── Target1
│   ├── BUILD
│   └── xxx.swift
├── Target2
│   ├── BUILD
│   └── xxx.m
├── TestTarget1
│   ├── BUILD
│   └── xxx.swift
├── TestTarget2
│   ├── BUILD
│   └── xxx.swift
└ ...
```

---

## `XCode Target` setting

 * [ ] type(application/framework/...)
 * [ ] setting
   * [ ] default setting
   * [ ] target setting
 * [ ] config(Debug/Release/...)
 * [ ] compile opts
     * [ ] swift
     * [ ] c
     * [ ] link
 * [ ] plist
     * [x] plist file
     * [ ] plist gen
 * [ ] xcconfig
 * [ ] srcs(`sourcesBuildPhase`)
     * [x] .swift -> `swift_library`
     * [ ] .m -> `objc_library`
     * [ ] .c -> `c_library`

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

 * XCode Target -> 中間層實作
 * 多語言 Target
 * 支援 plugin
 
### 多語言 Target 設計 (待討論)

1. 可參考 `PodToBUILD` 的實作方式。

[RxSwift (Generated by PodToBUILD)](RxSwift+PodToBUILD.md)

> 要順帶考慮 `naming rule`。

```bazel=
swift_library(
  name = "RxSwift_swift",
)
objc_library(
  name = "RxSwift",
  deps = [
    ":RxSwift_swift",
  ],
)
```

1. ...

### 支援 plugin

見 [Building and loading dynamic libraries at runtime in Swift](https://theswiftdev.com/building-and-loading-dynamic-libraries-at-runtime-in-swift/)

#### plugin interface

...

#### plugin loader

...


[Ref1]: https://www.youtube.com/watch?v=PPgiv7GLH6Y&ab_channel=GoogleOpenSource  "将大型 iOS 应用迁移至 Bazel"
