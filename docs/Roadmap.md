# Tree

## Goal

This is the ideal output tree after running `bazelize`.

- Tree layout is based on filesystem paths relative to `.xcodeproj`
- Tree layout does not follow Xcode logical groups
- Target metadata is handled by Bazel files instead of being emitted as files in the tree

## Root

```text
$Output/ <- Bazel Root
    BUILD
    MODULE.bazel
    Package.swift <- generated if have SwiftPM

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

Each target has its own directory under `Targets/`.

```text
Targets/
    $Target/
        BUILD
        Sources/
        Generated/
```

- `Sources/` contains all filesystem entries related to the target
- `Sources/` includes source files, headers, and resources
- file entries keep their original relative path from the `.xcodeproj` root
- directory entries are symlinked as directories and are not flattened
- multiple targets may reference the same source path

## Path Rules

- Paths are resolved from the `.xcodeproj` relative path
- Xcode logical groups do not affect output layout

Example:

```text
Xcode:
App
    UI
        A.swift

Real path:
A.swift

Output:
Sources/A.swift -> <real>/A.swift
```

Another example:

```text
Real paths:
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

Output:
Sources/A.swift -> <real>/A.swift
Sources/B/B.swift -> <real>/B/B.swift
Sources/C -> <real>/C
```

## Package Layout

Each Swift package the project depends on has its own directory under
`Packages/`, whoever generates its rules.

```text
Packages/
    $Package/
        BUILD
        Package/
        Generated/
```

- the directory is named after the package as a human reads it: the last path
  component of the URL without `.git`, or the directory name of a local package
- `Package/` is one symlink to the package's sources, remote or local
- a product is a label in this directory, so `//Packages/$Package:$Product` is
  what a target depends on regardless of how the rules are generated

See [SwiftPM](SPM.md) for what the rules themselves look like.

## Special Directories

- `Generated/` is target-local or package-local and reserved for files generated for it
- `Prebuilt/` is global at the root level and stores prebuilt binaries
- `Packages/` is global at the root level and stores the Swift packages' rules

## Deferred

- missing-file behavior will be defined later
