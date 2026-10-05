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
    Package.resolved <- kept from the project if it has one

    .bazelrc <- imports the three below
    config.bazelrc
    traits.bazelrc
    languages.bazelrc
    .bazelignore
    .bazelversion

    lint.sh
    format.sh
    plugins.sh
    plugin-host.swift
    plugin-plan.json

    tools/
        BUILD
        bazel
        list-config.sh
        list-trait.sh
        list-language.sh

    Targets/ <- only when the input is an Xcode project
        $Target1/
            BUILD
            Sources/
            Generated/

    Packages/
        BUILD
        $Package1/
            BUILD
            Sources/
                $PackageTarget1/
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

`Packages/` is generated output and is replaced as a unit on every run. Files
owned by the project belong beside it at the workspace root; a dependency or
target that leaves the resolved graph must not leave a buildable rule behind.

```text
Packages/
    $Package/
        BUILD
        Sources/
            $PackageTarget/
        Generated/
```

- the directory is named after the package as a human reads it: the last path
  component of the URL without `.git`, or the directory name of a local package
- `Sources/` holds one symlink per package target, pointing at that target's
  source directory in the checkout, remote or local; a tree whose symlinks form
  a cycle is mirrored entry by entry instead
- a product is a label in this directory, so `//Packages/$Package:$Product` is
  what a target depends on regardless of how the rules are generated

See [SwiftPM](SPM.md) for what the rules themselves look like.

## Special Directories

- `Generated/` is target-local or package-local and reserved for files generated for it
- `Prebuilt/` is global at the root level and stores prebuilt binaries
- `Packages/` is global at the root level and stores the Swift packages' rules

## Missing files

A file the project names and the disk does not have is left out of the target
and named at the end of the run. Xcode compiles what is there, so the generated
build does too, and the run says which file went missing rather than leaving a
compile error to say it indirectly.

A path that is not the project's own is not reported: a built product of
another target, an SDK framework, an absolute path, a header search path, and a
path that still carries an unexpanded build setting.
