# Bazelize

A cli tool turn your xcode project to bazel

---

## TODO

### Cocoapod

#### pod spec -> code gen

```bazel
//new_pod_repository(
//  name = "PINOperation",
//  url = "https://github.com/pinterest/PINOperation/archive/1.2.1.zip",
//)
```

#### XCode 查詢 target dependency -> code gen

#### 無效 pod spec 問題

#### 設計 Error -> help

#### 指令檢查 `pod is exist`? O

------

### Xcode


## todo code sytle

```swift
public func codeGenerate(_ path: Path) throws 
```

-----

## Bazel Rules

 * [rules_apple](https://github.com/bazelbuild/rules_apple/tree/master/doc)
 * [rules_swift](https://github.com/bazelbuild/rules_swift/blob/master/doc/rules.md#swift_proto_library)
 * [PodToBUILD](https://github.com/pinterest/PodToBUILD/blob/f96b6575452540a98791c170b637d46dec79bfac/BazelExtensions/workspace.bzl)
