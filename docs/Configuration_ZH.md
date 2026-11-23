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

v1 可設定 buildifier release 與選填的 cache 預設值。Bazel 與 BCR dependencies
的版本屬於 generator 管理的 pins，MUST NOT 複製到 `bazelize.yaml`。

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

### Cache 與本機覆寫

既有 schema-1 設定仍可使用，只需加入需要的 cache 欄位：

```yaml
cache:
  disk: ../cache/build
  repository: ../cache/downloads
  remote: https://cache.example.com
  upload-local-results: false
```

`--disk-cache`、`--repository-cache`、`--remote-cache` 與
`--remote-upload-local-results true|false` 分別覆寫對應的 YAML 欄位。
YAML 相對路徑以被選用的 YAML 所在目錄為基準，CLI 相對路徑以執行目錄為基準。
寫入 rc 時使用引號包住的絕對路徑，支援空白、引號及反斜線。空字串可停用從 YAML
繼承的路徑或 endpoint。遠端 endpoint 支援 HTTP(S)／gRPC(S)；內嵌帳號密碼或控制
字元會在修改生成目錄前被拒絕。認證請放在使用者／CI 設定，不要放入共享 YAML 或 URL。

每次生成都依本次 CLI／YAML 覆寫 `cache.bazelrc`；下次省略 CLI 選項時不沿用舊值。
專案擁有的 `.bazelrc` 保留其他內容，每個生成 import 只出現一次，最後加入
`try-import %workspace%/user.bazelrc`。`user.bazelrc` 可不存在，產生器不建立也不覆寫它。
包含本機路徑或認證時，請將它加入版本控制的忽略清單。

一般建置的優先順序是生成設定、`user.bazelrc`，再由直接傳給 Bazel 的參數覆寫。例如：

```sh
bazelize --input Example.xcodeproj --output App \
  --disk-cache '/Users/me/Library/Caches/bazel outputs' \
  --remote-cache https://cache.example.com --remote-upload-local-results false
```

Disk cache 保存 action 產物，repository cache 保存下載的依賴，remote cache 跨機器共享
action 產物。依團隊政策明確設定是否上傳；`false` 只讀取遠端產物、不上傳本機結果。
省略時沿用 Bazel 自身的上傳政策。

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
