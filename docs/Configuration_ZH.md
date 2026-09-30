# Bazelize 設定檔

## 狀態

本文定義已決定的 `bazelize.yaml` v1 contract，並記錄 v2 可能加入的項目。
v2 章節是設計 backlog，不是相容性承諾。

## Version 1

`bazelize init` 會產生以下檔案：

```yaml
schema: 1

buildifier:
  version: "10.1.0"
```

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
