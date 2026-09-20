# Roadmap Bazel File Design

## Goal

Extend the roadmap output so the generated workspace can move toward a real `bazel run //Example:Example` flow.

The first milestone is focused and intentionally incomplete:

- switch roadmap output from `Targets/<name>/...` to package-shaped directories like `<output>/Example/...`
- generate minimal `BUILD` files for the app package and the dependency target packages it needs
- generate a minimal `MODULE.bazel`
- generate a minimal root `Package.swift` for SwiftPM integration

This milestone is scoped to the `fixture/iOS2/Example.xcodeproj` style project and prioritizes the `Example` iOS app path.

## Output Shape

The output tree becomes:

```text
<output>/
    BUILD
    MODULE.bazel
    Package.swift
    Prebuilt/
        BUILD
    Example/
        BUILD
        Sources/
        Generated/
    Framework1/
        BUILD
        Sources/
        Generated/
```

This package-shaped layout is required so the final target path is naturally `//Example:Example` instead of `//Targets/Example:Example`.

## Bazel Rule Strategy

Use the existing Bazelize rule mapping as the model:

- application -> `ios_application`
- Swift sources -> `swift_library`
- ObjC sources -> `objc_library`
- framework target -> `ios_framework`
- static library target -> public `alias(name = "<Target>", actual = ":<Target>_library")`

Each package should expose a public top-level target matching the package name.

## Package-Specific Generation

### App Package

For `Example`:

- generate `swift_library(name = "Example_library", ...)`
- generate `ios_application(name = "Example", ...)`
- wire target deps from `target.dependencies.targets`
- wire SwiftPM deps from `target.dependencies.packageProducts`
- wire SDK frameworks from `target.dependencies.sdkFrameworks`
- add resources from the package `Sources/` tree

### Framework Package

For `Framework1`, `Framework2`, `Framework3`:

- generate the package language library target
- generate `ios_framework(name = "<Target>", ...)`
- depend on `:<Target>_library`
- depend on other target packages when needed

### Static Library Package

For `Static` and `Static2`:

- generate `swift_library` or `objc_library`
- generate `alias(name = "<Target>", actual = ":<Target>_library")`

## SwiftPM Strategy

`Example` depends on Swift package products, so a placeholder `MODULE.bazel` is not enough.

Generate a minimal root `Package.swift` from `Xcode.Project.packages`:

- remotes -> `.package(url: ..., ...)`
- locals -> `.package(path: ...)`

Generate a minimal `MODULE.bazel` with:

- `bazel_dep` entries for `bazel_skylib`, `rules_cc`, `rules_apple`, `rules_swift`, `rules_swift_package_manager`
- `swift_deps = use_extension(...)`
- `swift_deps.from_package(...)`
- `use_repo(...)` entries derived from package repository names

Package-product labels should follow the existing convention:

- remote package product -> `@swiftpkg_<repo>//:<Product>`
- local package product -> `@swiftpkg_<dirname>//:<Product>`

## Deferred

This milestone still defers:

- tests
- prebuilt binary import rules
- xcodeproj helper rules
- full `bazel run` success verification for every fixture target
- complete missing-file policy

## Testing

Add tests that verify:

- package-shaped output directories are created
- `Example/BUILD` contains `ios_application(name = "Example")`
- `Example/BUILD` contains `swift_library(name = "Example_library")`
- `Framework1/BUILD` contains `ios_framework(name = "Framework1")`
- `Static2/BUILD` contains `objc_library(name = "Static2_objc")`
- `MODULE.bazel` contains rules and SwiftPM extension wiring
