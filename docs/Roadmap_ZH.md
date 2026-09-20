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

    Targets/
        $Target1/
            BUILD
            Sources/
            Generated/

    Packages/
        $Package1/
            BUILD
            Package/
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
        Package/
        Generated/
```

- 目錄名取人看得懂的 package 名：remote 用 URL 最後一段去掉 `.git`，local 用目錄名
- `Package/` 是一條指向該 package 原始碼的 symlink，遠端或本地皆然
- product 就是這個目錄裡的 label，所以不論規則怎麼產生，target 依賴的都是
  `//Packages/$Package:$Product`

規則本身長什麼樣見 [SwiftPM](SPM_ZH.md)。

## Special Directories

- `Generated/` 是 target-local 或 package-local，保留給它專屬的 generated files
- `Prebuilt/` 是 root-level global directory，用來放 prebuilt binaries
- `Packages/` 是 root-level global directory，用來放 Swift package 的規則

## Deferred

- 缺檔時的處理行為之後再定義
