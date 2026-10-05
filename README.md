# Bazelize

Bazelize generates Bazel workspaces from Xcode projects and Swift packages.

---

## Install

```sh
mint install XCodeBazelize/Bazelize
```

## Usage

```sh
bazelize --input YOUR.xcodeproj --output App
```

Or a Swift package — the `Package.swift`, or the directory holding one:

```sh
bazelize --input path/to/Package.swift --output App
```

`generate` is the default subcommand, so `bazelize generate --input … --output
…` is the same command written out. `bazelize config init` and `bazelize dump`
are the other two.

A package whose targets use a build tool plugin has its plugins run at the end
of generation, with the `//:plugins` target the run writes:

```sh
bazel run //:plugins
```

Bazel builds the plugins and their tools, so generation needs `bazel` on `PATH`
for that step. Run the same command again whenever a plugin or its input
changes.

SwiftPM platform conditions stay in the generated rules. Settings, ordinary
dependencies, and macro dependencies use Bazel `select` expressions keyed by
the target platform, so generating once does not bake in the generator's host
or the Xcode project's platform.

Every generated workspace also owns its Starlark commands:

```sh
bazel run //:lint
bazel run //:format
```

Both pick the buildifier pinned for the host — `uname -s` and `uname -m`, so
macOS and Linux on arm64 or x86_64 — and download it into the user cache
against its checksum. `//:lint` reports warnings and fails on them; `//:format`
rewrites the generated `BUILD`, `WORKSPACE`, `*.bzl`, and `*.bazel` files the
way buildifier formats them. Formatting is buildifier's job, so generation does
not do it and `//:lint` reports a formatting difference rather than failing on
it.

An Xcode target whose product type is `com.apple.product-type.bundle` is
generated as a rules_apple `macos_bundle`.

A command plugin becomes a target named after its verb, so `swift package
hello` is:

```sh
bazel run //Packages/YourPackage:hello -- <arguments>
```

Everything after `--` reaches the plugin the way everything after the verb
reaches it under SwiftPM. There is no sandbox to widen, so what the plugin
declared it wants to do is printed rather than refused — running the target is
the permission.

### Configuration

Generation reads `bazelize.yaml` from the directory the input lives in: beside
an `.xcodeproj`, or in the root of a Swift package. A workspace without one is
generated from the defaults.

```yaml
schema: 1

buildifier:
  version: "10.1.0"
```

`bazelize config init` writes that file. `-o` says where: a directory to put
`bazelize.yaml` in, or the path of the file itself, defaulting to the current
one. Missing directories are created, and an existing file is never
overwritten.

```sh
cd path/to/project && bazelize config init   # beside the .xcodeproj or Package.swift
bazelize config init -o path/to/project      # the same place, named
bazelize config init -o config/custom.yaml   # for --config-file below
```

Use `--config-file path/to/custom.yaml` to read a file from somewhere else. An
explicit file takes precedence over that discovery; Bazelize does not merge
them. The buildifier version must be in Bazelize's checksum catalog. Bazel and
BCR dependency pins remain generator-owned and are not configuration
properties.

See [the configuration contract and v2 candidates](docs/Configuration.md).

---

## Bazel

### Project Hierarchy

Everything is written under `--output`; the input tree is not modified. A
generated workspace is self-contained — `MODULE.bazel`, not `WORKSPACE`:

```bash
App/                        # --output
├── MODULE.bazel            # the bazel_dep pins this workspace needs
├── BUILD                   # the `mode` flag, //:lint, //:format, //:plugins, //:xcodeproj
├── .bazelrc                # kept: user flags plus imports of the generated rc files
├── config.bazelrc          # generated: configurations and deployment floors
├── traits.bazelrc          # generated: SwiftPM trait selections
├── languages.bazelrc       # generated: one config per localization
├── .bazelignore            # keeps SwiftPM's .build out of the workspace
├── lint.sh, format.sh      # the buildifier pinned for the host
├── plugins.sh, plugin-host.swift, plugin-plan.json
├── .bazelversion
├── tools/                  # `bazel list config|trait|language`
├── Prebuilt/               # project-owned .framework/.a/.xcframework
├── Targets/<XcodeTarget>/  # Xcode input only
│   ├── BUILD
│   ├── Sources/            # symlinks into the original sources
│   └── Generated/          # entitlements, Info.plist, asset symbols
├── Packages/
│   ├── BUILD               # trait flags and the conditions rules select on
│   └── <Package>/          # BUILD, Sources/ symlinks, Generated/
├── Package.swift           # generated: the manifest SwiftPM resolves checkouts from
└── Package.resolved        # kept: the only source of pins
```

`Targets/` is what an Xcode input generates and `Packages/` is what its Swift
packages generate, so a package handed in directly produces the same workspace
without `Targets/`.

Generation preserves the workspace root and existing `.bazelrc` content, adding
each generated import once. `Targets/`, `Prebuilt/`, and `Packages/` are
generator-owned and rebuilt as units, so rules that leave the input graph
cannot remain part of `bazel build //...`.

### Config

An Xcode build configuration is a flag in the generated root `BUILD`:

```bazel
load("@bazel_skylib//rules:common_settings.bzl", "string_flag")

string_flag(
    name = "mode",
    build_setting_default = "Debug",
    values = [
        "Debug",
        "Release",
    ],
)

config_setting(
    name = "Debug",
    flag_values = {":mode": "Debug"},
)

config_setting(
    name = "Release",
    flag_values = {":mode": "Release"},
)
```

`config.bazelrc` names each one, and the generated `.bazelrc` imports it, so a
configuration is selected by name:

```sh
bazel build --config=Debug //Targets/Example
bazel build --//:mode=Debug //Targets/Example   # the same thing, spelled out
```
