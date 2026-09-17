# SwiftPM

## Goal

Bazelize generates the Bazel rules for a project's Swift packages itself. It
used to declare `rules_swift_package_manager` (rspm) in `MODULE.bazel` and
write a synthesized `Package.swift`, leaving rspm to generate the package
BUILD files inside an external repository at fetch time.

This document describes the **output shape**, the mapping from SwiftPM
concepts to rules, and how the switch was staged. It is about artifacts and
responsibility boundaries, not implementation details.

## Why

1. rspm's output needed 4 vendored patches for real projects
   (`Patches/rspm-*.patch` + `single_version_override`), plus a version gate.
2. We were pinned to rspm 1.15.0: from 1.16 every SwiftPM target is
   transitioned to the platform floor it declares itself, and analysis fails
   when a dependency declares a higher floor. Xcode never does this. Platform
   semantics are bazelize's own domain, so generating the rules here removes
   the conflict.
3. Header, resource and plist handling for Xcode targets already lives in
   bazelize; package targets behave consistently only if they share it.
4. The output is checked-in files: a problem is read in the file, not traced
   through a repo rule.
5. One fewer step — no `bazel mod tidy` to maintain the `use_repo` list.

The cost: SwiftPM semantics (traits, registry, binary targets, plugins, macros)
are now our responsibility, and so is the one behaviour still missing — a
package's own platform floor, at the end of this document.

## Previous output (rspm, for contrast)

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

The package BUILD files were not there; they were in
`external/rules_swift_package_manager++swift_deps+swiftpkg_<name>/`.

## Output

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
        ├── Generated/        # resource bundle accessors, module maps, plists
        ├── Sources/<Target>  # symlink to that target's sources
        └── Artifacts/<Target>/<Name>.xcframework   # binary targets
```

`Patches/` disappears entirely.

### How a package's sources get in

Every package — remote or local — is a directory in this workspace holding a
generated `BUILD` and one symlink per target into the sources SwiftPM already
has:

```text
Packages/SFSafeSymbols/
├── BUILD
└── Sources/
    └── SFSafeSymbols -> <workspace>/.build/checkouts/SFSafeSymbols/Sources/SFSafeSymbols
```

so a target's sources are globbed as `Sources/<Target>/**/*.swift`. A local
package points at wherever its manifest is, read in place.

Properties of this choice:

- Same shape as `Targets/`: a symlink tree plus a generated `BUILD` beside it.
  One mechanism, not two.
- No external repositories, so no `use_repo` list and no `bazel mod tidy`.
- Resolution stays SwiftPM's job: bazelize runs `swift package resolve` and
  reads each checkout's manifest with `swift package dump-package`, which is
  offline and spans every tools version in the graph.
- A link per target, rather than one for the whole checkout, keeps the rest of
  the checkout out of the build — a package may carry `BUILD` files of its own.

The alternative — one `git_repository` per remote package, pinned to the
revision in `Package.resolved` — is hermetic but reintroduces external repos
and fetches sources Bazel already has on disk.

### Label naming

Every package product — remote or local — has one shape in `Targets/*/BUILD`:

| Product of | Before | Now |
|---|---|---|
| a remote package | `@swiftpkg_sfsafesymbols//:SFSafeSymbols` | `//Packages/SFSafeSymbols:SFSafeSymbols` |
| a local package | `@swiftpkg_account//:Account` | `//Packages/Account:Account` |

The directory is named after the package as a human reads it (last path
component of the URL without `.git`, or the directory name for a local
package), so a name with a dot — `//Packages/GRMustache.swift:Mustache` —
works too.

A product is that label whatever generates it, which is what made the switch a
change to `Packages/` alone: the label shape landed first, as aliases into
rspm, and became the rules themselves without a single target's `deps` moving.
No test pins how a package's rules are produced either.

## SwiftPM concept → generated rule

| SwiftPM | Generated |
|---|---|
| Swift target | `swift_library` |
| clang target (C/ObjC/C++) | `objc_library` + `swift_interop_hint`, and a module map when the package ships none |
| system-library target | `cc_library` + `swift_interop_hint` over the module map the package ships |
| binary target (xcframework) | `apple_dynamic_xcframework_import` / `apple_static_xcframework_import` |
| binary target (local archive) | unarchived first, then as above |
| library product, one target | `alias` |
| library product, several targets | `swift_library_group` |
| `.process` / `.copy` resources | `apple_resource_bundle` + `Generated/<Target>ResourceBundleAccessor.swift` |
| auto-discovered resources (xib/xcassets/metal/xcstrings/`.lproj`) | as above; a `.metal` file takes the target's headers into the resource group, because the bundler compiles them as Metal headers |
| `defines` | `-D` flags, not the `defines` attribute, which would propagate to every dependent |
| `headerSearchPath` | `includes`, and the headers there stay inputs even when `exclude` drops the directory |
| `linkedLibrary` / `linkedFramework` | `linkopts` |
| `swiftLanguageMode` | `-swift-version` |
| `enableUpcomingFeature` / `enableExperimentalFeature` | `-enable-upcoming-feature` / `-enable-experimental-feature` |
| `defaultIsolation` | `-default-isolation <value>` |
| `interoperabilityMode` | `-cxx-interoperability-mode=<value>` |
| `strictMemorySafety` | `-strict-memory-safety` |
| `unsafeFlags` | `copts` |
| build tool plugin (SwiftLint etc.) | not run; the plugin is named at the end of the run |
| macro target | `swift_compiler_plugin`, and `plugins` on whatever declares the macro |
| traits (SE-0450) | expanded into `-D` and conditional deps per enabled trait |

Two SwiftPM behaviours are matched on every generated `swift_library`:
`alwayslink`, because SwiftPM always links a package library, and
`always_include_developer_search_paths`, which is how a test-support library
such as `RxTest` finds XCTest. Every generated rule is also tagged `manual`: a
package target is built through the bundle rule that transitions it to a
platform, so a wildcard pattern must not compile an iOS-only package for the
host.

A C-family target's public headers are linked into a generated interface
directory with its module map beside them, and that directory is the header
search path. clang looks for `module.modulemap` in the directory a header was
found in, so the map has to sit next to the headers, and the checkout is not
ours to write into. A module map is what names a C-family module. Without one the module is named
after the label and the target cannot be imported by the name its own sources
use; a module map the package ships is preferred, because it is the interface
the package intends. Reaching it through a header search path is what lets every
consumer resolve the module — Swift or C-family, this package, another one, or an
Xcode target — since only a Swift consumer is handed a module by the rules.

A package's sources are linked one target at a time, so the rest of a checkout
stays out of the build, and `.bazelignore` keeps SwiftPM's working directory
out of it too. Both exist for the same reason: a package can carry `BUILD`
files of its own, and Bazel would load them as packages of this workspace.

A package's platform floor is deliberately ignored — honouring it per package
is exactly the rspm behaviour that pins us to 1.15.0. What that costs is in
stage 2's results below.

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
The iOS fixture declares one instead, so the rules for a macro are exercised by
a build rather than by inspection.

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
| macros, source-generating plugins | 0 (none in the corpus; the fixture has a macro) |

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

At this stage only pure-Swift package targets were generated, behind a flag
with rspm still the default. A target whose
kind is not generated yet is skipped with a warning, and so is every target
that depends on it: a library missing a target it links is worse than a library
that is not there at all.

Across the 7 green macOS apps, `bazel build //...`:

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

## Stage 2 results (measured)

Every kind of target a package in the corpus is made of is generated: C-family,
resource-carrying, binary and system-library targets, next to the Swift ones.

`bazel build //...`, followed by launching the app:

| app | result |
|---|---|
| MonitorControl, SwiftBar, stats, Rectangle, MacPass, iina, VirtualBuddy | build and run |
| CodeEdit | every package builds; the app's own sources are rejected by Swift 6.4 |
| CotEditor | every package builds; the app's own sources are rejected by Swift 6.4 |
| IceCubesApp | every package builds; the app's own sources collide with the iOS 27 SDK (`SwiftUI.Document`) |
| UTM | its packages build; the app needs a prebuilt sysroot, and one source imports a header by basename through Xcode's project headermap |
| PlayCover | `swift package resolve` fails on the package's own manifest |

The four that do not build fail in code that is not generated here: three in
their own sources against a newer compiler and SDK, one in a package manifest
upstream.

### Platform versions

A package declares the platform versions it supports, and SwiftPM compiles each
of its targets at the higher of that and the consumer's. Bazelize compiles every
package target at the project's deployment target: the version lives in the
platform transition of the bundle rule that pulls the target in, and a library
rule has no version of its own. Honouring it per target is what pinned the rspm
dependency at 1.15.0 — later versions transition each target to its own floor
and then fail analysis when a dependency declares a higher one.

The version a package asks for is still decided, the way SwiftPM decides it:

1. what the manifest's `platforms:` declares for that platform;
2. else the oldest version SwiftPM builds that platform for — macOS 12, iOS and
   tvOS 15, watchOS 9, visionOS 1, Mac Catalyst 15, DriverKit 21;
3. else, for a platform the project builds without naming a version, what the
   installed SDK reports: the deployment target of the `XCTest` it ships, which
   is how SwiftPM asks the same question.

That version is compared with the lowest deployment target among the project's
own targets. A package that needs more is named at the end of the run, with both
versions, because the failure otherwise surfaces as an availability error deep
in someone else's source.

Compiling such a package at the version it asks for is not the answer, because
SwiftPM does not do that either. It rejects the graph:

```text
error: The package product 'Dep-product' requires minimum platform version 14.0
for the macOS platform, but this target supports 12.0
```

A module built for a newer platform cannot be imported by an older one — Swift
errors on that too — so the only resolution is the project raising its own
deployment target, or the package lowering what it declares. Saying which
package and which two versions is therefore the whole of it.

The same experiment shows SwiftPM raises *both* sides to its own floor before
comparing them (the project above declares macOS 11 and is reported as 12), so a
package that declares nothing is never the reason a graph is rejected. Only a
version a manifest states is reported here.

## Stages and exit criteria

The exit criterion is the same at every stage: **the 12 apps at least hold
their ground** (the 7 green ones stay green, the blocked ones keep the same
reason), plus the 114 unit tests and the iOS fixture.

| Stage | Scope | Goal |
|---|---|---|
| 0 ✅ | measure the corpus | see above |
| 0.5 ✅ | the `//Packages` facade (aliases into rspm) | all apps; label shape settled |
| 1 ✅ | pure Swift library targets, `swiftLanguageMode` / `define` / upcoming and experimental features / `strictMemorySafety` / `defaultIsolation` / `interoperabilityMode` / `unsafeFlags`; unsupported kinds skipped with a warning, together with their dependents; behind a flag, rspm still the default | 58 packages build on their own |
| 2 ✅ | clang targets (`headerSearchPath` / `publicHeadersPath` / explicit `sources` / `exclude` / module maps), resources + `Bundle.module` accessor, binary targets (remote xcframework and local archive), system libraries | the 7 green apps build and run; every package of the other five builds |
| 3 | macro targets ✅; per-target platform versions ✅ (nothing to build — SwiftPM rejects such a graph, so the report is the answer); source-generating build tool plugins remain | when something outside the corpus needs it |
| 4 ✅ | the rspm dependency, `Patches/`, the version gate and the mode flag are gone | the 7 green apps build and run |

Stage 4 removed the alternative rather than keeping a flag: two paths would
mean two dependency graphs, and the generated one is at least as good on every
app in the corpus.

## Open questions

1. Does `Package.swift` still need to be part of the output? Only
   `swift package resolve` reads it, so it could be generated only when pins
   are updated.
2. Which stage supports registry packages (`.package(id:)`)? Nothing in the
   corpus uses one.
3. Should the four rspm patches still go upstream? They are small and useful to
   whoever still uses rspm.
