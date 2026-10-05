## 套件管理(Dependecy Management)

---

### 常見的套件管理

從目前常見的套件管理中，主要分別為:

 * `Cocoapod`
 * `Carthage`
 * `SPM`

上述三者當中，只有 `Carthage` 無法得知其相依套件與 `Target` 對應關係，因此我們先放棄 `Carthage` `deps` 的實作。


`SwiftPM` 的 Bazel 規則由 bazelize 直接讀取套件的 manifest 後產生，不經由
`rules_swift_package_manager` 之類的第三方規則。`Cocoapod` 沒有實作，當初的研究筆記
已封存在 [docs/archive/](archive/)。

----

## 套件的必要屬性

 * 套件來源(`url`/`local path`)
   * carthage: `github "SVProgressHUD/SVProgressHUD"` -> `https://github.com/svprogresshud/SVProgressHUD`
 * 套件版本(`tag`/`commit`)，常見存放於 `xxx.lock` file。
   * 例外: `local path` 無需版本。
   * carthage: `github "SVProgressHUD/SVProgressHUD" "2.2.5"` -> `tag: "2.2.5"`
 * 對應關係(`Xcode Target` vs `Module`)

```ruby
# Xcode Target `Target1` -> Module `SVProgressHUD`
target 'Target1' do
    pod 'SVProgressHUD'
end
```

----

### 套件管理(Carthage)

我們先來説說 `Carthage`，`Carthage` 主要是依靠 `Cartfile` 宣告其相依。

```carthage
# Cartfile
github "SVProgressHUD/SVProgressHUD"
```

```carthage
# Cartfile.resolved
github "SVProgressHUD/SVProgressHUD" "2.2.5"
```

#### 套件管理(Carthage) 條件

 * [x] 套件來源
 * [x] 套件版本
 * [ ] 對應關係

---

### 套件管理(SPM_Xcode)

> `.lock` 位於
> `xxx.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`

----

#### Package.resolved(version 1)

```json
{
  "object": {
    "pins": [
      {
        "package": "Rainbow",
        "repositoryURL": "https://github.com/onevcat/Rainbow",
        "state": {
          "branch": null,
          "revision": "626c3d4b6b55354b4af3aa309f998fae9b31a3d9",
          "version": "3.2.0"
        }
      }
    ]
  },
  "version" : 1
}
```

----

#### Package.resolved(version 2)

```json
{
  "pins" : [
    {
      "identity" : "alertkit",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/X-Team/AlertKit.git",
      "state" : {
        "branch" : "custom",
        "revision" : "39b01c53ffadf3dab9871dd4c960cd81af5246b6"
      }
    }
  ],
  "version" : 2
}
```

---

#### 套件管理(SPM_Xcode) 條件

 * [x] 套件來源
 * [x] 套件版本
 * [x] 對應關係

