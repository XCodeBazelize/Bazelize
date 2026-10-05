# Bazelize

---

## `Bazelize` Objectives

 1. Migrating to `bazel` with minimal impact on existing `Xcode` projects.
     * See [Ref](#Ref)
 2. Migrating `xxx.xcodeproj` and its dependencies to `bazel`, for example, `spm` (`pod` is not supported yet).

----

### Parsing `xcodeproj`

The project is parsed by [XcodeProj](https://github.com/tuist/XcodeProj) to get the `Xcode Target` settings, and then filled into the corresponding `rules`.

(Follow-up implmentation direction: `Xcode Target` -> middle layer -> generate code)

> `Xcode Target` is treated as [Bazel Packages](https://docs.bazel.build/versions/4.2.1/build-ref.html#packages)

See [`Xcode Target` setting](Design_ZH.md#xcode-target-setting) (only written in the Chinese version so far)
---

## Dependency Management

See [Dependecy](Dependecy_ZH.md)
---

## Design of Bazelize

----

### xxx_library

First, let's talk about the code part. Our code will be applied to special rules, such as `xxx_library`.

A `xxx_library` rule only covers one language, so the language of the sources decides which rule we emit:

 * Swift only -> `swift_library`
 * C family (`.c`/`.m`/`.mm`/`.cc`) only -> `objc_library`
 * both -> `mixed_language_library` (from `rules_swift`)

> A mixed target gets the Objective-C side of the module through the generated header `${module_name}-Swift.h`,
> and the Swift side through the bridging header / module map.


### `Xcode Target` type

We will start with the `Xcode Target` type, and then we will implement the most common types.

See [PBXProductType][product_type].

#### Identifying `Xcode Target` type

The criterion are [PBXProductType][product_type] and [XCConfigurationList][config_list].

### `Xcode Target` + `Naming Rule`

`BUILD` file contains two types of rules, `xxx_library` and `main rule`.

Suppose `Framework2` is an `iOS Framework` written in Objective-C.

The `xxx_library` is named `TargetName + _xxx`, so it is `Framework2_objc`
(`_swift` for `swift_library`, `_mixed` for `mixed_language_library`).

Since the consumer does not care which language implements the library, an `alias`
named `TargetName + _library` points at it.

```bazel
objc_library(
    name = "Framework2_objc",
)
alias(
    name = "Framework2_library",
    actual = "Framework2_objc",
    visibility = ["//visibility:public"],
)
```

The `main rule` is picked from the `Xcode Target` type (`iOS Framework` -> `ios_framework`)
and keeps the target name itself.

```bazel
ios_framework(
    name = "Framework2",
    deps = [":Framework2_library"],
)
```

The package path is `Targets/<XcodeTarget>`, so another target depends on it through
`//Targets/Framework2:Framework2_library`.
