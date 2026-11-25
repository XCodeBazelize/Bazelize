# SwiftPM fixtures

One package per thing SwiftPM can do, named after the thing. Each is small
enough to read in a minute, and each one's tests only pass if bazelize
generated that thing correctly — a package that builds but asserts nothing
would not tell us anything.

| package | what it holds bazelize to |
|---|---|
| `ArtifactBundle` | a binary target that ships a program: the plugin's tool comes out of an `.artifactbundle`, and the source it writes is what the target compiles |
| `BinaryTarget` | a local zipped XCFramework, which links statically |
| `BuildToolPlugin` | a build tool plugin and the tool it runs: the test target only compiles through a source the plugin generates |
| `Clang` | the C-family shapes: Objective-C, Objective-C++, assembly, public headers somewhere of its own, a private header search path, defines with and without a value, a module map the package ships, C and C++ `unsafeFlags`, the package's language standards, C++ interoperability, the bundle a C target reaches without importing anything, and tests written in XCTest as well as swift-testing — plus a test target written in Objective-C, which compiles as a C-family one |
| `CommandPlugin` | a plugin that is run on demand rather than while building, with the permissions such a plugin asks for, which nothing in a build may grant it or try to run |
| `ConfigurationCondition` | settings conditional on debug and release, which the build decides rather than the generator |
| `DependencyCondition` | dependencies conditional on a platform and on a trait: what the condition excludes must not be built |
| `DependencyShape` | how a dependency is named: `.target`, by name, `.product`, a package whose identity is neither its directory nor its manifest name, two packages shipping a product of the same name, `moduleAliases` renaming a module that would otherwise clash, and a dependency's own resource bundle |
| `DeploymentFloor` | the deployment target the package graph declares, which every compile outside a bundle rule's platform transition has to get: a back-port that is `obsoleted:` above that floor compiles only at it |
| `ExecutableResource` | resources reaching a program that has no Apple bundler to embed them: a command line tool's own `.copy`, `.process` and asset catalogue, plus a library it links whose `Bundle.module` only resolves when that library's bundle travels with the tool |
| `Macro` | a macro target, loaded by the compiler while the target beside it is compiled |
| `Platform` | platform-conditional settings and dependencies as build-time `select` expressions: the same generated rule takes the macOS branch on the host, the iOS branch through an iOS platform transition, and combines platform with debug configuration |
| `MixedLanguage` | one target holding C, Objective-C and Swift, which is one module: a consumer imports `Unified` once and reaches the Swift API and the C functions, and Objective-C calls back into Swift through the generated `Unified-Swift.h`. Needs a Swift 6.5 toolchain |
| `PluginDependency` | a build tool plugin that belongs to another package, named with the package it comes from, running that package's tool |
| `PrebuildPlugin` | a plugin's `.prebuildCommand`, which names a directory rather than the files it writes |
| `ProductShapes` | products over several targets: `.static`, `.dynamic` and automatic libraries, a product named after one of its own targets, an executable product under another name, and a `Snippets/` program |
| `RemoteXCFramework` | a remote XCFramework SwiftPM fetches, which links dynamically |
| `RemoteArtifactBundle` | a binary target whose program is fetched rather than found: SwiftPM checks the archive against its checksum and unpacks it where nothing local ever sits, and the plugin's tool comes out of there |
| `SwiftSettings` | every `SwiftSetting` and `LinkerSetting`, plus the package's own `swiftLanguageModes`, a target that overrides it, and a dependency declaring none at all so its tools version decides: upcoming and experimental features, strict memory safety, default isolation, unsafe flags, warnings treated as errors with one group put back to a warning, a linked library, a linked framework, and linker flags — each one observable, so a setting that went missing fails the build |
| `SystemLibrary` | system-library targets: module maps whose `link` and `link framework` directives say what to link, and a library whose header only `pkg-config` knows the way to — which is why this one needs `PKG_CONFIG_PATH` (see below) |
| `Trait` | the package's own traits, a default one, and a dependency whose trait is turned on by name |
| `TraitGraph` | the whole trait graph: traits that enable traits, a condition naming several, and dependencies taking `.defaults`, nothing, or a named selection |
| `TargetSources` | `sources:`, where a file beside the listed ones must not be compiled, and a link back to the target's own directory that must not be walked |
| `TargetPath` | `path:`, where neither the target nor its tests are under `Sources/` |
| `TargetExclude` | `exclude:` naming a directory and a single file, neither of which may be compiled — in a package that declares no products at all |
| `TargetEmbed` | `.embedInCode`, the one rule with no bundle at all: the file's bytes are a generated source |
| `TargetResource` | every other resource rule: `.copy` of a directory and of a single file, `.process`, an explicit localization, two `.lproj` directories, an asset catalogue, a xib, a storyboard, a data model with two versions, a shader that includes a header, a string catalogue, a privacy manifest, a test target's own resources, and the `.docc` SwiftPM ignores |
| `RegistryPackage` | a dependency named by registry identity (`.package(id:)`), unpacked where SwiftPM unpacks a registry download — CI builds/tests the generated workspace using the offline download below |

Every package of a fixture builds and — where it has tests — passes them, the
package beside the one bazelize is pointed at included: those are dependencies
with sources of their own, and one that stopped building should be found here
rather than in whatever it broke.

The `SwiftSettings` CI lane also runs
`python3 .github/scripts/check-package-warnings.py ./bazelize`. It creates a
temporary Git dependency with warning-producing Swift sources and warning
controls in its manifest. SwiftPM and the generated Bazel build must reject it
as a root or local path package, while an external dependency's consumer must
build and execute successfully. The external consumer is built in both debug
and optimized configurations. The dependency is fetched from a local repository,
and temporary packages are removed afterward. The manual/tag `Compatibility`
workflow also converts and builds the pinned `swift-composable-architecture`
product that exposed #68.

`ConfigurationCondition` runs native debug/release and Bazel default/optimized
tests, including checking that the release compilation selects only its release
define. `Platform` keeps its native/macOS control and condition checks in the
fixture lane; separate SDK jobs execute iOS/tvOS/watchOS Simulator tests and
compile visionOS Simulator and physical-device bundles. These compile-only jobs
do not claim runtime coverage. Every fixture's generated Starlark is checked
after its existing generation rather than generated again solely for lint.

`.xcmappingmodel` is the one resource kind with no fixture: its source is a
Core Data XML persistent store that only Xcode's modeler writes — a hand-written
one is rejected by `mapc` — so there is nothing to check in. Nothing about it is
particular to bazelize either: it is globbed and grouped exactly as
`.xcdatamodeld` is, which is built and asserted, and what would compile it is
rules_apple's own action. The versioned model covers what migration is built
on: both versions in the bundle, with a mapping derivable between them.

## The registry fixture

`RegistryPackage` has an offline Bazel build/test lane. No registry is reachable
from this repository, so the native root build is deliberately not used as a
control. A registry dependency reaches a build as an archive SwiftPM unpacked
under `App/.build/registry/downloads/<scope>/<name>/<version>`, and that directory
is all generation reads. CI seeds the checked-in `Registry/` contents there
before generation, using the same setup as the unit test:

```sh
cd spm/RegistryPackage
mkdir -p App/.build/registry/downloads
cp -R Registry/. App/.build/registry/downloads/
bazelize --input . --output App
cd App && bazel test //...
```

`swift build` on this package does not work without a registry configured for
the `bazelize` scope, and neither does `swift package resolve` — generation
says so and carries on with what is unpacked. CI requires that note, then runs
the generated Bazel tests. `Tests/XcodeTests/RegistryPackageTests.swift` separately
checks the generated dependency identity and the expected resolution note.

What that leaves uncovered is resolution itself: fetching, checksum
verification and version selection are SwiftPM's, happen before anything here
runs, and need a real registry to exercise.

A package that must not compile a file says so in the file: it is a
`#error(…)`, so a generator that globs too much fails loudly instead of
quietly passing. What must not be *linked* says so where it would have been
linked, so the package holding it still builds anywhere.

## Running one

```sh
cd spm/<package>
bazelize --input . --output App
cd App
bazel run //:plugins   # re-runs the build tool plugins; generation already ran them once
bazel run //:lint      # reports every generated Starlark warning
bazel run //:lint-ci   # fails only on reviewed behavior-affecting warnings
bazel test //...
bazel run //tools:list-config   # what `--config=<name>` the workspace defines
bazel run //tools:list-trait    # which traits its packages declare, and which are on
bazel run //tools:list-language # which localizations they ship
bazel test //... --config=<Package>.<Trait>   # …with one of them turned on
bazel test //... --config=<Package>.none      # …with the package's defaults off
bazel test //... --config=<Package>.all       # …with every trait it declares on
bazel build //... --config=lang.<code>        # …bundling that localization only
```

A package that wraps a system library is found through `pkg-config`, and the
one `SystemLibrary` ships is in the fixture rather than on the machine, so both
SwiftPM and bazelize need to be told where it is:

```sh
cd spm/SystemLibrary
export PKG_CONFIG_PATH="$PWD/vendor/pkgconfig"
swift test
bazelize --input . --output App
```

The flags are read when the workspace is generated, so only that command needs
the variable — the build does not.

`bazel test //... --config=<Package>.<Trait>` is that package built with that
trait selected: the selection replaces the package's defaults and carries
whatever the trait enables, which is what `swift test --traits <trait>` does.
The flags underneath are there for a build that wants some other combination.

`bazel run //:plugins` runs this workspace's build tool plugins and writes what
they generate into `Packages/<package>/Generated/`. Generation ends with that
command, so a freshly generated workspace already has what they write; running
it again is how a plugin or an input of one is picked up, without generating
the workspace a second time. Bazel builds the generated host, the plugins and
their tools, then runs all of them from runfiles; no `bazelize` executable is
needed at runtime.

`bazel run //:lint` downloads the buildifier pinned for the host — `uname -s`
and `uname -m`, so macOS and Linux on arm64 or x86_64 — verifies and caches it,
then reports every generated Starlark warning. `bazel run //:lint-ci` checks only
the repository's reviewed behavior-affecting warning categories. Bazelize
already writes generated files in canonical format; formatting differences fail
neither command, and `bazel run //:format` rewrites files changed afterward.

`bazel build --config=lang.<code>` bundles that localization and `Base`, and
nothing else; a build that names none bundles every one of them, which is what
SwiftPM does. Several at once is the flag underneath,
`--@build_bazel_rules_apple//apple/build_settings:locales_to_include=en,ja`.

The listing commands are generated Bazel targets and do not need `bazelize` at
runtime either. The generated `tools/bazel` wrapper also exposes them as
`bazel list config|trait|language`.

`App/` is generated, and is not checked in.

`TargetEmbed` is run with `swift test --build-system native`. On the toolchain
that lane was written against, `swiftbuild` generated nothing for
`.embedInCode` — Xcode 27's does — while `native` has generated it all along,
so the lane names the build system that implements the rule rather than
inheriting whichever the runner ships. Its Bazel side is built the same way as
every other fixture.

`MixedLanguage` is a mixed Swift/C/Objective-C target and needs SwiftPM from a
Swift 6.5 toolchain (`// swift-tools-version: 6.5`), so it has its own
`MixedLanguage` CI job rather than a lane in `IntegratePackage`, and the older
toolchains of the other lanes never read its manifest. The contract is one
module: `Unified` is a single SwiftPM target and a single Bazel module, so a
consumer writes `import Unified` once and calls both `SwiftAPI.value` (42) and
`unified_c_value()` (41); `unified_round_trip(5)` goes C-family to Swift and
back and is 93. Its C settings (a define with and without a value, a header
search path, `cLanguageStandard`), Swift define, custom `publicHeadersPath` and
a test target that is itself mixed are each asserted, in swift-testing and
XCTest. The C defines also reach the Clang module Swift imports underneath, which
`UNIFIED_HEADER_FLAG` in the public header checks.

Both interfaces also reach whatever depends on `Unified`. `ObjCConsumer` is
Objective-C only: one `@import Unified;` gives it the C functions and the Swift
class exposed to Objective-C, so `objc_consumer_total(1)` is 85. `MixedConsumer`
is itself mixed, and both of its halves use both halves of `Unified`:
`MixedConsumerAPI.total` (Swift) is 83 and `MixedConsumerAPI.objc(1)`
(Objective-C) is 129. The executable and the tests depend on all three. CI
inspects the `SwiftInfo` of `Unified` and `MixedConsumer`: each has one direct
module, named after the target, with both Swift and Clang inputs. Internal
compilation targets do not introduce another public module. `Downstream/` is
another package that depends on the `Unified` product through `path: ".."`: its
Objective-C target `@import`s `Unified` and its Swift executable calls both
interfaces, and CI runs it through SwiftPM and through its own generated
workspace (`bazel run //Packages/Downstream:downstream-consumer`).

Bazelize generates a mixed target only from a 6.5 manifest; an older one keeps
the Swift-only classification SwiftPM gives it. A regular or test target becomes
one `mixed_language_library`. An `.internal` `bridgingHeader` is passed with
`-internal-import-bridging-header`, and a conditional one is reported rather
than guessed. A mixed executable or macro target is reported: its C-family
sources are not compiled, so put them in a library the program depends on. The
fixture does not claim every feature of the mixed-target proposal.

The `MixedLanguage` CI job downloads no toolchain. It uses the runner's default
Xcode and runs the fixture only when `swift --version` reports 6.5 or newer;
otherwise the job reports a notice and skips every step after the check. Locally,
run it with a Swift 6.5 toolchain selected:

```sh
cd spm/MixedLanguage
swift build && swift test && swift run unified-consumer   # prints "unified ok"
bazelize --input . --output App
cd App
bazel test //...
bazel run //Packages/MixedLanguage:unified-consumer      # prints "unified ok"
```

With a development snapshot rather than an Xcode that ships Swift 6.5, put the
snapshot's `usr/bin` first on `PATH` for SwiftPM, and give Bazel
`--action_env=TOOLCHAINS=<snapshot identifier>` while keeping
`--repo_env=TOOLCHAINS=com.apple.dt.toolchain.XcodeDefault`: rules_swift's SDK
discovery fails under the snapshot's compiler.
