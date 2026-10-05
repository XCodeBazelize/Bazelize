# Bazelize 設定檔

## 狀態

本文定義已決定的 `bazelize.yaml` v1 contract，並記錄 v2 可能加入的項目。
v2 章節是設計 backlog，不是相容性承諾。

## Version 1

`bazelize config init` 會產生以下檔案：

```yaml
schema: 1

buildifier:
  version: "10.1.0"
```

產生器是從輸入所在的目錄讀這個檔，所以它就該放在那裡。`-o` 指定寫到哪：可以是要放
`bazelize.yaml` 的目錄，也可以是檔案本身的路徑，預設是目前目錄。

```sh
cd path/to/project && bazelize config init
bazelize config init -o path/to/project
bazelize config init -o config/custom.yaml   # 之後用 `generate --config-file` 指定
```

不存在的目錄會自動建立。既有的檔案會造成錯誤，絕不覆寫。

v1 只允許設定 buildifier release。Bazel 與 BCR dependencies 的版本屬於
generator 管理的 pins，MUST NOT 複製到 `bazelize.yaml`。

### 選擇順序

`bazelize generate` 依下列順序選擇唯一的設定來源：

1. `--config-file` 指定的路徑；
2. 輸入 `.xcodeproj` 旁，或 Swift package root 內的 `bazelize.yaml`；
3. Bazelize 編譯時內建的預設值。

明確指定的檔案不存在或內容無效時會直接失敗。Bazelize 不會合併明確指定與自動找到的兩份設定。

### 驗證

- `schema` 必填且 MUST 為 `1`。
- 未知 property 直接視為錯誤。
- `buildifier.version` 必填。
- buildifier version MUST 存在於 Bazelize 的 release catalog；catalog 保存產生
  lint command 時所需的各平台 checksum。

### Release catalog

`BazelDep+Buildifier.swift` 由 `repo-enum` package plugin 依 `RepoSources.yml`
產生，內含 GitHub release API 回報的各 asset SHA-256 digest。

只有同時滿足以下兩點的 release 才會被產生：

- `release_assets` 列出的每個 host 在該 GitHub release 都有 SHA-256 digest，
  產生出來的 lint command 才能在任一 host 上執行；
- Bazel Central Registry 有登錄 `RepoSources.yml` 指定 module 的該版本，
  因此 `latest` 不可能是 `bazel_dep` 解析不到的版本。

host 以 `uname` 的說法命名：`os` 是小寫的 `uname -s`，`machine` 是 `uname -m`。
產生的 `lint.sh` 就是以此判斷，要支援新 host 只需在 `RepoSources.yml` 補上它的
asset。

其他 dependency 版本本來就取自 registry `metadata.json`，並排除 yanked 版本。
`Bazel` 是例外：它寫進 `.bazelversion` 而非以 module 形式請求，所以版本來自
repository 的 release tags。

### 刻意不放入 v1 的項目

- Xcode configuration 繼續由 `-c` command-line option 指定。
- 目前固定產生的 features 維持啟用。
- 不提供 target selection。
- generation 不會自動格式化 source 或 generated files。

## Version 2 可能加入的項目

以下候選項目必須先有具體 use case 與 migration semantics，才能納入正式 contract。

### Target selection

```yaml
targets:
  exclude:
    - LegacyApp
```

尚未決定的 contract：

- 名稱是完整 Xcode target name，還是允許 pattern；
- 排除 dependency 時，應一併排除 dependants，還是直接失敗；
- Swift package products 與 generated plugin targets 如何命名。

保守預設是只接受完整名稱，遇到 dependency 關係時明確報錯。

### Feature switches

```yaml
features:
  lint: true
  xcodeproj: true
```

只有在停用某個 generated surface 能解決實際成本或相容性問題時，才加入 switch。
key 應描述使用者可見能力，不應暴露內部 plugin class 名稱。

### Buildifier policy

```yaml
buildifier:
  version: "10.1.0"
  warnings: all
```

`warnings` 可用來控制 `//:lint` 傳給 buildifier 的 warning set。自動格式化仍不在
設定範圍內；formatting 應由明確指令觸發。

## Version 2 非目標

除非 ownership model 改變，以下項目不應放進設定檔：

- Bazel、`rules_*` 與其他 BCR dependency pins；
- 由 `Package.resolved` 決定的 Swift package versions；
- Xcode build configuration selection；
- 任意 Starlark 或 shell injection；
- generator 內部 plugin 名稱。
