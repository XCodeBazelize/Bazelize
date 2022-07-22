# Bazelize

---

## `Bazelize` Objectives

 1. Migrating to `bazel` with minimal impact on existing `XCode` projects.
     * See [Ref](#Ref)
 2. Migrating `xxx.xcodeproj` and its dependencies to `bazel`, for example, `pod`, `spm`.
     * See [Dependecy](Dependecy_ZH.md)

----

### Parsing `xcodeproj`

The project is parsed by [XcodeProj](https://github.com/tuist/XcodeProj) to get the `XCode Target` settings, and then filled into the corresponding `rules`.

(Follow-up implmentation direction: `XCode Target` -> middle layer -> generate code)

> `Xcode Target` is treated as [Bazel Packages](https://docs.bazel.build/versions/4.2.1/build-ref.html#packages)

See [`XCode Target` setting](#XCode-Target-setting)
---

## Dependency Management

See [Dependecy](Dependecy.md)
---

## Design of Bazelize

----

### xxx_library

First, let's talk about the code part. Our code will be applied to special rules, such as `xxx_library`.

(Currently, only `xxx_library` can be applied to the same language)

We are currently focusing on `swift_library` and `objc_library` implementations.

Fortunately, `XCode Target` seems to support only one language.

> Except for application, we can use `bridge-header` or generated header `RxSwift-Swift.h`


### `XCode Target` type

We will start with the `XCode Target` type, and then we will implement the most common types.

See [PBXProductType][product_type].

#### Identifying `XCode Target` type

The criterion are [PBXProductType][product_type] and [XCConfigurationList][config_list].

### `XCode Target` + `Naming Rule`

`BUILD` file contains two types of rules, `xxx_library` and `main rule`.

(working in progress)
