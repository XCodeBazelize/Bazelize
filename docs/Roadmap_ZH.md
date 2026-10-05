# Tree

## 目標

這是目前理想中 `bazelize` 執行完成後的輸出目錄結構。

- tree layout 以 `.xcodeproj` 相對路徑為準
- tree layout 不依照 Xcode logical groups 呈現
- target metadata 不會以檔案形式輸出，而是交由 Bazel files 處理

## Root

```text
$Output/ <- Bazel Root
    BUILD
    MODULE.bazel
    Package.swift <- 如果有 SwiftPM 則產生
    Package.resolved <- 專案有的話沿用

    .bazelrc <- import 下面三個
    config.bazelrc
    traits.bazelrc
    languages.bazelrc
    .bazelignore
    .bazelversion

    lint.sh
    format.sh
    plugins.sh
    plugin-host.swift
    plugin-plan.json

    tools/
        BUILD
        bazel
        list-config.sh
        list-trait.sh
        list-language.sh

    Targets/ <- 只有輸入是 Xcode 專案時才有
        $Target1/
            BUILD
            Sources/
            Generated/

    Packages/
        BUILD
        $Package1/
            BUILD
            Sources/
                $PackageTarget1/
            Generated/

    Prebuilt/
        BUILD
        A.xcframework
```

## Target Layout

每個 target 都會在 `Targets/` 底下有自己的目錄。

```text
Targets/
    $Target/
        BUILD
        Sources/
        Generated/
```

- `Sources/` 包含所有和該 target 相關的實體檔案系統 entry
- `Sources/` 內包含 source files、headers、resources
- file entry 會保留其相對於 `.xcodeproj` 的原始子路徑
- directory entry 會直接以 directory symlink 的形式保留，不會展平
- 多個 target 可以共享同一個來源路徑

## Path Rules

- 所有路徑都以 `.xcodeproj` 相對路徑解析
- Xcode logical groups 不影響輸出 layout

範例：

```text
Xcode:
App
    UI
        A.swift

實際路徑:
A.swift

輸出:
Sources/A.swift -> <real>/A.swift
```

另一個範例：

```text
實際路徑:
A.swift
B/B.swift
C/
    a.swift
    b.swift
    c.swift

Target entries:
A.swift
B/B.swift
C/

輸出:
Sources/A.swift -> <real>/A.swift
Sources/B/B.swift -> <real>/B/B.swift
Sources/C -> <real>/C
```

## Package Layout

專案依賴的每個 Swift package 都會在 `Packages/` 底下有自己的目錄，不論它的規則
是誰產生的。

```text
Packages/
    $Package/
        BUILD
        Sources/
            $PackageTarget/
        Generated/
```

- 目錄名取人看得懂的 package 名：remote 用 URL 最後一段去掉 `.git`，local 用目錄名
- `Sources/` 底下每個 package target 一條 symlink，指向 checkout 裡該 target 的
  原始碼目錄，遠端或本地皆然；若該目錄的 symlink 構成迴圈，則改為逐項鏡像
- product 就是這個目錄裡的 label，所以不論規則怎麼產生，target 依賴的都是
  `//Packages/$Package:$Product`

規則本身長什麼樣見 [SwiftPM](SPM_ZH.md)。

## Special Directories

- `Generated/` 是 target-local 或 package-local，保留給它專屬的 generated files
- `Prebuilt/` 是 root-level global directory，用來放 prebuilt binaries
- `Packages/` 是 root-level global directory，用來放 Swift package 的規則

## 缺檔

專案提到、但磁碟上沒有的檔案會被排除在 target 之外，並在執行結束時具名回報。
Xcode 編得了什麼，產生出來的 build 就編什麼；缺了哪個檔案由執行過程說出來，
而不是留給之後的編譯錯誤間接表達。

不屬於專案自身的路徑不會回報：其他 target 的產物、SDK framework、絕對路徑、
header search path，以及仍帶著未展開 build setting 的路徑。
