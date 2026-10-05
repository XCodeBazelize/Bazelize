### 套件管理(Cocoapod)

> 封存：研究筆記，bazelize 沒有實作。原本在 `docs/Dependecy_ZH.md` 的
> 「常見的套件管理」之下，與 Carthage／SPM 兩節並列。以下文字原樣保留。

```ruby
# Podfile
target 'Target' do
  inhibit_all_warnings!
  pod 'SVProgressHUD'
end
```

```yaml
# Podfile.Lock
PODS:
  - SVProgressHUD (2.2.5)

DEPENDENCIES:
  - SVProgressHUD

SPEC REPOS:
  https://github.com/CocoaPods/Specs.git:
    - SVProgressHUD

SPEC CHECKSUMS:
  SVProgressHUD: 1428aafac632c1f86f62aa4243ec12008d7a51d6

PODFILE CHECKSUM: 59e0f0beb00fc64afe764xxxxxxxx

COCOAPODS: 1.11.3
```

#### Podfile to json

> `pod ipc podfile-json Podfile`

```json
{
  "target_definitions": [
    {
      "name": "Pods",
      "abstract": true,
      "user_project_path": "xxx.xcodeproj",
      "children": [
        {
          "name": "Target1",
          "uses_frameworks": {
            "linkage": "dynamic",
            "packaging": "framework"
          },
          "dependencies": [
            {
              "SVProgressHUD": [
                {
                  "git": "https://github.com/SVProgressHUD/SVProgressHUD",
                  "tag": "2.2.5"
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

#### 套件管理(Cocoapod) 條件

 * [ ] 套件來源
   * [ ] 大部分 Pod，會支援其 git 來源
   * [ ] 少部分 Pod 並無提供來源
 * [ ] 套件版本
 * [ ] 對應關係
