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

The `.xcodeproj` input can contain either the traditional `project.pbxproj` or
Xcode 27.2's JSON-based `project.xcproj`. Pass the enclosing `.xcodeproj`
directory to both `generate` and `dump`. CI builds and tests both formats,
using Xcode 27.2's native converter to prepare the JSON project.
SDK frameworks link by their framework name in either format, including
SDK-relative references whose display names Xcode's JSON converter omits.

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
bazel run //:lint-ci
bazel run //:format
```

All three pick the buildifier pinned for the host — `uname -s` and `uname -m`,
so macOS and Linux on arm64 or x86_64 — and download it into the user cache
against its checksum. Bazelize writes generated Starlark in that buildifier's
canonical format. `//:lint` is the complete report. `//:lint-ci` enforces only
the reviewed behavior-affecting categories: `constant-glob`, `duplicated-name`,
`no-effect`, `return-value`, `uninitialized`, and `unreachable`. Formatting
differences do not fail either check; `//:format` rewrites generated `BUILD`,
`WORKSPACE`, `*.bzl`, and `*.bazel` files changed after generation.

An Xcode target whose product type is `com.apple.product-type.bundle` is
generated as a rules_apple `macos_bundle`.

For targets with `GENERATE_INFOPLIST_FILE = YES`, generated Info.plist fragments
preserve `INFOPLIST_KEY_CFBundleDisplayName`. App extensions require a non-empty
display name to install in the iOS Simulator. After changing these settings or
updating Bazelize, regenerate the workspace before running the application:

```sh
bazelize --input YOUR.xcodeproj --output App
cd App && bazel run //Targets/YourApp
```

A command plugin becomes a target named after its verb, so `swift package
hello` is:

```sh
bazel run //Packages/YourPackage:hello -- <arguments>
```

If a product already owns that name, the plugin target appends `_command`
until its label is unique.

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

Common cache settings are available as CLI options and optional YAML defaults:

```sh
bazelize --input YOUR.xcodeproj --output App \
  --disk-cache '/Users/me/Library/Caches/bazel outputs' \
  --repository-cache /Users/me/Library/Caches/bazel-downloads \
  --remote-cache https://cache.example.com --remote-upload-local-results false
```

CLI values override individual YAML cache fields. Each run replaces
`cache.bazelrc`; local paths and authentication can live in an optional,
user-owned `user.bazelrc`, imported after generated settings and preserved on
regeneration. Keep credentials out of shared configuration and version control.

See [the configuration contract and v2 candidates](docs/Configuration.md).

---

## Bazel

Generated workspaces pin Bazel **9.2.0**, `rules_apple` **5.4.0**,
`rules_swift` **4.2.2**, `apple_support` **2.12.0**, and `rules_cc` **0.2.28**.
The Apple rules use the versioned bundle layout for macOS frameworks.

For `rules_swift` 4.2.2, generated workspaces include a source patch under
`tools/rules_swift`, applied through `single_version_override`. It is the
upstream fix [rules_swift#2015](https://github.com/bazelbuild/rules_swift/pull/2015),
which no release carries yet (4.3.0 does not). It keeps framework module maps
discoverable through `-F` without adding their `Modules/` directories to `-I`, so
Objective-C consumers of generated Swift headers can import binary frameworks
such as Sparkle or SVProgressHUD. Non-framework Clang modules retain their
include paths. The iOS fixture's `Mixed` target is a Swift and Objective-C
framework that fails to build without the patch; it is what tells a version bump
whether the patch is still needed.

### Project Hierarchy

Everything is written under `--output`; the input tree is not modified. A
generated workspace is self-contained — `MODULE.bazel`, not `WORKSPACE`:

```bash
App/                        # --output
├── MODULE.bazel            # the bazel_dep pins this workspace needs
├── BUILD                   # the mode flag, lint commands, //:plugins, //:xcodeproj
├── .bazelrc                # kept: user flags plus imports of the generated rc files
├── config.bazelrc          # generated: configurations and deployment floors
├── traits.bazelrc          # generated: SwiftPM trait selections
├── languages.bazelrc       # generated: one config per localization
├── cache.bazelrc           # generated: current CLI/YAML cache settings
├── user.bazelrc            # optional, kept: local overrides and authentication
├── .bazelignore            # keeps SwiftPM's .build out of the workspace
├── lint.sh, lint-ci.sh, format.sh  # the buildifier pinned for the host
├── plugins.sh, plugin-host.swift, plugin-plan.json
├── .bazelversion
├── tools/                  # `bazel list config|trait|language`, asset_symbols.bzl
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

Declared checkout inputs missing from disk are named in generation notes and
omitted from every generated input attribute. Resolving their nearest existing
ancestor preserves the same relative path under a real or symlinked project root.

### Per-file compiler flags

C-family sources with `COMPILER_FLAGS` are grouped by their ordered arguments in
private `objc_library` rules; the original public target still links the whole
module and owns its published headers. ARC-only overrides use `non_arc_srcs`,
including mixed Swift/Objective-C targets, so the remaining sources keep ARC.
`fixture/iOS` includes a macOS `PerFileFlags` program that checks MRC destruction,
default ARC, and a macro confined to one source at runtime.

Swift per-file flags and general C-family overrides inside mixed Swift modules
cannot be represented without changing the module. Generation names each file
and omitted flag and still produces the workspace. Compiler flags containing
unresolved build-setting references are also reported.


### Asset symbols

`ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS` makes Xcode turn
a catalog into Swift members the target compiles. No ruleset wraps `actool` for
that, so the workspace carries the rule itself in `tools/asset_symbols.bzl`. It
runs `actool` as an Apple action: the selected Xcode is part of the action's key,
so symbols are not reused across Xcode versions, and the platform comes from the
configuration the target is built in — the project's own SDK is only the
fallback for a build that carries no Apple platform constraint. CI diffs the
result against the file Xcode writes into `DerivedSources`.

### Application icons

For iOS applications, `ASSETCATALOG_COMPILER_APPICON_NAME` selects the primary
Icon Composer `.icon` bundle or legacy `.appiconset`. Explicit alternate icon
names and `ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS=YES` select the
target's alternate icons, including bundles in synchronized folders. A legacy
set with the primary's name remains an input when supplied for older systems.

The generated workspace patches its pinned rules_apple 5.4.0 to compile mixed
Icon Composer and legacy inputs for deployment targets below 26. The actool
wrapper materializes `.icon` files inside the consuming action, because a copy
in a preceding action becomes symlinks again in the consumer's sandbox.
actool generates the primary and alternate declarations in the final Info.plist.

### Integration corpus

Ordinary PR checks and pushes to `master`/`main` run the Swift suite, every local
SwiftPM fixture, both Xcode project formats, and native/generated product
comparisons. Platform host tests stay with the local fixture; separate matrix
jobs execute iOS, tvOS, and watchOS Simulator tests and compile visionOS Simulator
and device bundles. Compile-only jobs do not claim runtime execution. Generated
Starlark is checked in the workspaces these jobs already generated, without
resolving the entire fixture graph again in a separate lint job.

The Xcode-format parity check generates independent workspace roots and preserves
both roots. It compares all generated files and executable bits, excluding only
SwiftPM `.build` state. Absolute links into each workspace are relocated to one
comparison root; external link destinations and link/file types remain distinct.
Both formats also execute the per-file compiler-flag probe.

The external corpus is eight applications and nine Swift packages at pinned
revisions. It runs only through the **Compatibility** workflow's **Run workflow**
button, or when a version tag such as `0.1.0` or `v0.1.0` is pushed. There is no
nightly schedule and no external corpus on ordinary PR or branch pushes. Manual
runs select a branch or tag; both manual and tag runs build their own matching
Bazelize binary. The workflow must first exist on the default branch before
GitHub enables manual dispatch. Once available, a PR branch can be checked with:

```sh
gh workflow run compatibility.yml --ref YOUR_BRANCH
```

Run it before merging changes to project loading, SwiftPM resolution, plugins,
code generation, or toolchain/rules pins. The PR checklist links to the workflow
so this step is visible. Tag validation checks the tagged commit after the tag
is pushed; it does not publish a release or replace pre-merge validation. Exact
external revisions and measured exclusions live in
`.github/workflows/compatibility.yml`; they never follow upstream branch heads.

Bazel downloads and action outputs use separate caches. Only the repository's
default branch writes shared caches; PRs and tags restore that mainline baseline.
Action-output archives are partitioned by selected Xcode/Swift toolchain, runner
architecture, and fixture/SDK. Download archives are shared across compatible
jobs, with one designated writer per workflow. SwiftPM build state is similarly
partitioned by toolchain and package/configuration. Cache snapshots are immutable
and refreshed per mainline commit; GitHub's normal storage and eviction policy
still applies. PR-local cache entries are not a source for other PRs. No remote
cache service or paid storage increase is configured.

iOS Simulator tests name a device type and no OS version. The `rules_apple`
runner then runs them on the runtime the selected Xcode pairs with its SDK, and
the CI boot helper picks its device from that same runtime. A version is not
passed because it cannot name a runtime: device-specific runtimes share a
version with the general one while supporting different devices.

CI also compares controlled bundles against their native builds. The
`TargetResource` fixture compares SwiftPM's library and test resource bundles
with the generated `apple_resource_bundle` outputs; macOS's
`Contents/Resources` wrapper is normalized, while every logical resource,
property-list value, node type, and stable byte is compared in both directions.
The fixture's `MacBundle.bundle` similarly compares the complete Xcode and
`macos_bundle` product trees, including the executable's architectures, build
platform, dependencies, exported symbols, and rpaths. Known differences are
named in a checked-in baseline; a new difference or one that disappears fails
CI until the baseline is updated.

### Swift code style

Use [nicklockwood/SwiftFormat](https://github.com/nicklockwood/SwiftFormat), pinned
in `mise.toml`, with `.swiftformat` as the shared rule set:

```sh
mise install swiftformat
make install-hooks
make format
```

`make format` formats only changed project Swift files, including new files that
are not ignored; it never stages them. Review the result and stage the intended
changes. Before opening a PR, include files changed since the actual base:

```sh
python3 scripts/format-swift.py --base origin/master
```

The local pre-commit hook checks staged blobs with the staged `.swiftformat`
configuration. It never rewrites the working tree or index, so partially staged
edits remain separate. Generated workspaces and external checkouts are excluded
by Git's tracked/ignored-file selection. `make build` and CI never run SwiftFormat.

### Unsupported targets

A target whose product type — or, for an application, whose platform — has no
rule here stops generation with an error naming it. A workspace that silently
omits a target is a workspace that builds the wrong thing. A target that has no
sources of its own is still reported as a note and skipped: there is nothing to
bundle.

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
