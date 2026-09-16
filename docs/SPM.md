# SwiftPM

## Goal

Generate the Bazel rules for a project's Swift packages in bazelize, instead of
delegating them to `rules_swift_package_manager` (rspm).

Today bazelize only declares rspm in `MODULE.bazel` and writes a synthesized
`Package.swift`; rspm generates the package BUILD files inside an external
repository at fetch time.

This document describes the **output shape** after the switch, the mapping from
SwiftPM concepts to rules, and the staged plan. It is about artifacts and
responsibility boundaries, not implementation details.

## Why

1. rspm's output needs 4 vendored patches for real projects
   (`Patches/rspm-*.patch` + `single_version_override`), plus a version gate.
2. We are pinned to rspm 1.15.0: from 1.16 every SwiftPM target is transitioned
   to the platform floor it declares itself, and analysis fails when a
   dependency declares a higher floor. Xcode never does this. Platform
   semantics are bazelize's own domain, so generating the rules here removes
   the conflict.
3. Header, resource and plist handling for Xcode targets already lives in
   bazelize; package targets behave consistently only if they share it.
4. The output becomes checked-in files: a problem is read in the file, not
   traced through a repo rule.
5. One fewer step — no `bazel mod tidy` to maintain the `use_repo` list.

The cost: SwiftPM semantics (traits, registry, binary targets, plugins, macros)
become our responsibility.

## Current output (rspm, for contrast)

```text
App/
├── MODULE.bazel              # bazel_dep(rules_swift_package_manager)
│                             # + swift_deps.from_package + use_repo(...)
│                             # + single_version_override(patches = …)
├── Patches/                  # vendored rspm patches, version gated
│   ├── BUILD
│   └── rspm-*.patch
├── Package.swift             # synthesized manifest, read by rspm
├── Package.resolved          # seeded from Xcode's Package.resolved
├── config.bazelrc
├── BUILD
├── Prebuilt/                 # project-owned .framework/.a/.dylib (symlinks)
└── Targets/<XcodeTarget>/
    ├── BUILD
    ├── Sources/              # symlink tree into the original sources
    ├── Headers/<Module>/     # flattened header tree
    ├── Generated/            # BazelizeDefines.h, entitlements, asset symbols
    └── CopyFiles/<dest>/     # copy phase destinations
```

The package BUILD files are not here; they are in
`external/rules_swift_package_manager++swift_deps+swiftpkg_<name>/`.

## New output (generated here)

```text
App/
├── MODULE.bazel              # no rspm
├── Package.swift             # kept: SwiftPM still resolves the graph
├── Package.resolved          # kept: the only source of pins
├── config.bazelrc
├── BUILD
├── Prebuilt/
├── Targets/<XcodeTarget>/    # unchanged
└── Packages/                 # ★ new
    └── <PackageName>/
        ├── BUILD             # the rules for every target of that package
        ├── Generated/        # resource bundle accessors, modulemaps, defines
        └── Package           # symlink to the package's sources
```

`Patches/` disappears entirely.

### How a package's sources get in

Every package — remote or local — is a directory in this workspace holding a
generated `BUILD` and one symlink to the sources SwiftPM already has:

```text
Packages/SFSafeSymbols/
├── BUILD
└── Package -> <workspace>/.build/checkouts/SFSafeSymbols
```

so a target's sources are globbed as `Package/Sources/<Target>/**/*.swift`.
A local package points at wherever its manifest is, read in place.

Properties of this choice:

- Same shape as `Targets/`: a symlink tree plus a generated `BUILD` beside it.
  One mechanism, not two.
- No external repositories, so no `use_repo` list and no `bazel mod tidy`.
- Resolution stays SwiftPM's job: bazelize runs `swift package resolve` and
  reads each checkout's manifest with `swift package dump-package`, which is
  offline and spans every tools version in the graph.

The alternative — one `git_repository` per remote package, pinned to the
revision in `Package.resolved` — is hermetic but reintroduces external repos
and fetches sources Bazel already has on disk.

### Label naming: the facade

Every package product — remote or local — has one shape in `Targets/*/BUILD`:

| Product of | Before | Now |
|---|---|---|
| a remote package | `@swiftpkg_sfsafesymbols//:SFSafeSymbols` | `//Packages/SFSafeSymbols:SFSafeSymbols` |
| a local package | `@swiftpkg_account//:Account` | `//Packages/Account:Account` |

In rspm mode `Packages/<Name>/BUILD` is a layer of aliases pointing at whatever
implements the product today:

```python
alias(
    name = "SFSafeSymbols",
    actual = "@swiftpkg_sfsafesymbols//:SFSafeSymbols",
    visibility = ["//visibility:public"],
)
```

The directory is named after the package as a human reads it (last path
component of the URL without `.git`, or the directory name for a local
package), so a name with a dot — `//Packages/GRMustache.swift:Mustache` —
works too.

What this buys: **replacing the SwiftPM implementation only touches files under
`Packages/`**. No target's `deps` changes when the aliases become the rules
themselves, reverting means pointing the aliases back at rspm, and no test pins
rspm's repository naming.

## SwiftPM concept → generated rule

| SwiftPM | Generated |
|---|---|
| Swift target | `swift_library` |
| clang target (C/ObjC/C++) | `objc_library`, reusing bazelize's header/include logic |
| mixed target | `mixed_language_library` |
| system-library target | `cc_library` + a generated modulemap |
| binary target (xcframework) | `apple_dynamic_xcframework_import` / `apple_static_xcframework_import` |
| binary target (local archive) | unarchived first, then as above |
| library product, one target | `alias` |
| library product, several targets | `swift_library_group` |
| `.process` / `.copy` resources | `apple_resource_bundle` + `Generated/<Target>ResourceBundleAccessor.swift` |
| auto-discovered resources (xib/xcassets/metal/xcstrings) | as above; `.metal` enters the resource group with that target's headers |
| `defines` | `defines` (an unsafe value goes through `Generated/<Target>Defines.h`, same policy as an Xcode target) |
| `headerSearchPath` | `includes` |
| `linkedLibrary` / `linkedFramework` | `linkopts` |
| `swiftLanguageMode` | `-swift-version` |
| `enableUpcomingFeature` / `enableExperimentalFeature` | `-enable-upcoming-feature` / `-enable-experimental-feature` |
| `defaultIsolation` | `-default-isolation <value>` |
| `interoperabilityMode` | `-cxx-interoperability-mode=<value>` |
| `strictMemorySafety` | `-strict-memory-safety` |
| `unsafeFlags` | `copts` |
| build tool plugin (SwiftLint etc.) | stage 3; skipped with a warning |
| macro / compiler plugin | stage 3; `swift_compiler_plugin` |
| traits (SE-0450) | expanded into `-D` and conditional deps per enabled trait |

Two SwiftPM behaviours are matched on every generated `swift_library`:
`alwayslink`, because SwiftPM always links a package library, and
`always_include_developer_search_paths`, which is how a test-support library
such as `RxTest` finds XCTest. Each library is also tagged `manual`: a package
target is built through the bundle rule that transitions it to a platform, so a
wildcard pattern must not compile an iOS-only package for the host.

A package's platform floor is deliberately ignored — honouring it per package
is exactly the rspm behaviour that pins us to 1.15.0.

## Stage 0 results (measured)

Corpus: the **119 packages / 208 non-test targets** the 12 apps expand to, read
from the `dump.json` and `desc.json` rspm generates in its external repos (the
output of `swift package dump-package` and `describe`).

### Target kinds

| module type | count |
|---|---|
| SwiftTarget | 170 |
| ClangTarget | 50 |
| BinaryTarget | 2 |
| SystemLibraryTarget | 2 |
| PluginTarget | 1 |

No macro targets, and no mixed-language targets (SwiftPM does not allow them).

### Build settings (targets / packages using them)

| setting | targets | packages |
|---|---|---|
| `swift.enableUpcomingFeature` | 116 | 5 |
| `c.headerSearchPath` | 44 | 28 |
| `swift.strictMemorySafety` | 23 | 4 |
| `swift.enableExperimentalFeature` | 21 | 14 |
| `swift.define` | 14 | 4 |
| `swift.swiftLanguageMode` | 13 | 13 |
| `swift.defaultIsolation` | 10 | 10 |
| `c.define` | 6 | 3 |
| `linker.linkedLibrary` | 1 | 1 |
| `linker.linkedFramework` | 1 | 1 |
| `swift.unsafeFlags` | 1 | 1 |

### Other shapes

- **resources**: 32 packages (37 `.copy`, 4 `.process`) → resource bundles and
  a `Bundle.module` accessor are required.
- **manifest shape**: 30 targets list `sources` explicitly, 32 use `exclude`,
  33 set `publicHeadersPath` → file collection for a clang target cannot rely
  on convention alone.
- **tools version** ranges from 4.2 to 6.3 (most common: 5.3, 30 packages).
- **plugin usage**: 9 packages, **all SwiftLint** (`SwiftLintPlugin` 5,
  `SwiftLintPlugins` 4) — lint only, they generate no source.
- **plugin target**: exactly one, swift-argument-parser's `GenerateManual`,
  consumed by nobody in the corpus.
- **binary target**: 2 (Sparkle's remote xcframework, CodeEditLanguages' local
  `.zip`).

### What that means

Taking "skip a lint-only build tool plugin with a warning" and "do not generate
a plugin target nobody consumes" as rules, **all 119 packages fall into stages
1–2**:

| Scope of the stage | Packages covered |
|---|---|
| pure Swift libraries, no resources | 58 |
| + clang / resources / binary / system | 61 (119 cumulative) |
| macros, source-generating plugins | 0 (none in the corpus) |

The minimum stage each app needs (expanded from each workspace's
`Package.resolved`):

| app | pins | needs |
|---|---|---|
| Rectangle | 2 | stage 2 |
| SwiftBar | 5 | stage 2 |
| MonitorControl | 6 | stage 2 |
| iina | 4 | stage 2 |
| IceCubesApp | 20 | stage 2 |
| VirtualBuddy | 6 | stage 2 (only needs argument-parser's plugin target skipped) |
| UTM | 15 | stage 2 (same) |
| PlayCover | 8 | stage 2 (same) |
| CotEditor | 29 | stage 2 (+ SwiftLint plugin skipped) |
| CodeEdit | 34 | stage 2 (+ SwiftLint plugin skipped) |

So **macros and real plugins can be deferred as a whole**: stage 2 covers the
entire corpus.

## Stage 1 results (measured)

`--spm native` generates rules for pure-Swift package targets. A target whose
kind is not generated yet is skipped with a warning, and so is every target
that depends on it: a library missing a target it links is worse than a library
that is not there at all.

Native mode across the 7 green macOS apps, `bazel build //...`:

| app | result | blocking target kind |
|---|---|---|
| stats | builds | — |
| MacPass | builds | — |
| MonitorControl | needs stage 2 | Sparkle, binary target |
| SwiftBar | needs stage 2 | Sparkle, binary target |
| Rectangle | needs stage 2 | MASShortcut, clang target |
| iina | needs stage 2 | GRMustache.swift's `GRMustacheKeyAccess`, clang target |
| VirtualBuddy | needs stage 2 | BuddyKit, clang target |

Every failure is a missing target kind, not a wrong rule: the products that
reference a skipped target are the only unresolved labels.

## Stages and exit criteria

The exit criterion is the same at every stage: **the 12 apps at least hold
their ground** (the 7 green ones stay green, the blocked ones keep the same
reason), plus the 114 unit tests and the iOS fixture.

| Stage | Scope | Goal |
|---|---|---|
| 0 ✅ | measure the corpus | see above |
| 0.5 ✅ | the `//Packages` facade (aliases into rspm) | all apps; label shape settled |
| 1 ✅ | pure Swift library targets, `swiftLanguageMode` / `define` / upcoming and experimental features / `strictMemorySafety` / `defaultIsolation` / `interoperabilityMode` / `unsafeFlags`; unsupported kinds skipped with a warning, together with their dependents; behind `--spm native`, default still rspm | 58 packages build on their own |
| 2 | clang targets (`headerSearchPath` / `publicHeadersPath` / explicit `sources` / `exclude`), resources + `Bundle.module` accessor, binary targets (remote xcframework and local archive), system libraries | all 12 apps at least hold their ground |
| 3 | macros / source-generating build tool plugins | when something outside the corpus needs it |
| 4 | flip the default, drop the rspm dependency, `Patches/` and the version gate | everything |

Through stages 1–3 rspm and the native generator are **never mixed**: a
workspace takes one path or the other, chosen by the flag. Mixing them would
produce two dependency graphs.

## Open questions

1. Does `Package.swift` still need to be part of the output? Only
   `swift package resolve` reads it, so it could be generated only when pins
   are updated.
2. Which stage supports registry packages (`.package(id:)`)? Nothing in the
   corpus uses one.
3. Should the rspm patches still go upstream during stages 1–4? They are small
   and useful to others, so probably yes.
