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
| `Clang` | the C-family shapes: Objective-C, Objective-C++, assembly, public headers somewhere of its own, a private header search path, defines with and without a value, a module map the package ships, C and C++ `unsafeFlags`, the package's language standards, C++ interoperability, the bundle a C target reaches without importing anything, and tests written in XCTest as well as swift-testing |
| `CommandPlugin` | a plugin that is run on demand rather than while building, with the permissions such a plugin asks for, which nothing in a build may grant it or try to run |
| `ConfigurationCondition` | settings conditional on debug and release, which the build decides rather than the generator |
| `DependencyCondition` | dependencies conditional on a platform and on a trait: what the condition excludes must not be built |
| `DependencyShape` | how a dependency is named: `.target`, by name, `.product`, a package whose identity is neither its directory nor its manifest name, two packages shipping a product of the same name, `moduleAliases` renaming a module that would otherwise clash, and a dependency's own resource bundle |
| `Macro` | a macro target, loaded by the compiler while the target beside it is compiled |
| `Platform` | what a platform decides and when: a setting conditional on a platform an Apple toolchain builds is kept, one conditional on Linux or Windows is gone before the rules are written, and the package's own deployment target is what its rules are built for |
| `PluginDependency` | a build tool plugin that belongs to another package, named with the package it comes from, running that package's tool |
| `PrebuildPlugin` | a plugin's `.prebuildCommand`, which names a directory rather than the files it writes |
| `ProductShapes` | products over several targets: `.static`, `.dynamic` and automatic libraries, a product named after one of its own targets, an executable product under another name, and a `Snippets/` program |
| `RemoteXCFramework` | a remote XCFramework SwiftPM fetches, which links dynamically |
| `RemoteArtifactBundle` | a binary target whose program is fetched rather than found: SwiftPM checks the archive against its checksum and unpacks it where nothing local ever sits, and the plugin's tool comes out of there |
| `SwiftSettings` | every `SwiftSetting` and `LinkerSetting`, plus the package's own `swiftLanguageModes` and a target that overrides it: upcoming and experimental features, strict memory safety, default isolation, unsafe flags, a linked library, a linked framework, and linker flags — each one observable, so a setting that went missing fails the build |
| `SystemLibrary` | system-library targets: module maps whose `link` and `link framework` directives say what to link, and a library whose header only `pkg-config` knows the way to — which is why this one needs `PKG_CONFIG_PATH` (see below) |
| `Trait` | the package's own traits, a default one, and a dependency whose trait is turned on by name |
| `TraitGraph` | the whole trait graph: traits that enable traits, a condition naming several, and dependencies taking `.defaults`, nothing, or a named selection |
| `TargetSources` | `sources:`, where a file beside the listed ones must not be compiled, and a link back to the target's own directory that must not be walked |
| `TargetPath` | `path:`, where neither the target nor its tests are under `Sources/` |
| `TargetEmbed` | `.embedInCode`, the one rule with no bundle at all: the file's bytes are a generated source |
| `TargetResource` | every other resource rule: `.copy` of a directory and of a single file, `.process`, an explicit localization, two `.lproj` directories, an asset catalogue, a xib, a storyboard, a data model with two versions, a shader that includes a header, a string catalogue, a privacy manifest, a test target's own resources, and the `.docc` SwiftPM ignores |

Every package of a fixture builds and — where it has tests — passes them, the
package beside the one bazelize is pointed at included: those are dependencies
with sources of their own, and one that stopped building should be found here
rather than in whatever it broke.

`.xcmappingmodel` is the one resource kind with no fixture: its source is a
Core Data XML persistent store that only Xcode's modeler writes — a hand-written
one is rejected by `mapc` — so there is nothing to check in. Nothing about it is
particular to bazelize either: it is globbed and grouped exactly as
`.xcdatamodeld` is, which is built and asserted, and what would compile it is
rules_apple's own action. The versioned model covers what migration is built
on: both versions in the bundle, with a mapping derivable between them.

A package that must not compile a file says so in the file: it is a
`#error(…)`, so a generator that globs too much fails loudly instead of
quietly passing. What must not be *linked* says so where it would have been
linked, so the package holding it still builds anywhere.

## Running one

```sh
cd spm/<package>
bazelize --project . --output App
cd App
bazel run //:plugins   # only the packages with a build tool plugin need this
bazel test //...
bazel run //tools:list-config   # what `--config=<name>` the workspace defines
bazel run //tools:list-trait    # which traits its packages declare, and which are on
bazel run //tools:list-language # which localizations they ship
bazel test //... --config=<Package>.<Trait>   # …with one of them turned on
bazel build //... --config=lang.<code>        # …bundling that localization only
```

A package that wraps a system library is found through `pkg-config`, and the
one `SystemLibrary` ships is in the fixture rather than on the machine, so both
SwiftPM and bazelize need to be told where it is:

```sh
cd spm/SystemLibrary
export PKG_CONFIG_PATH="$PWD/vendor/pkgconfig"
swift test
bazelize --project . --output App
```

The flags are read when the workspace is generated, so only that command needs
the variable — the build does not.

`bazel test //... --config=<Package>.<Trait>` is that package built with that
trait selected: the selection replaces the package's defaults and carries
whatever the trait enables, which is what `swift test --traits <trait>` does.
The flags underneath are there for a build that wants some other combination.

`bazel run //:plugins` runs this workspace's build tool plugins and writes what
they generate into `Packages/<package>/Generated/`. It is a separate step
because a plugin is a program: Bazel builds it, and bazelize runs it as SwiftPM
would.

`bazel build --config=lang.<code>` bundles that localization and `Base`, and
nothing else; a build that names none bundles every one of them, which is what
SwiftPM does. Several at once is the flag underneath,
`--@build_bazel_rules_apple//apple/build_settings:locales_to_include=en,ja`.

The listing commands are generated Bazel targets and do not need `bazelize` at
runtime. The generated `tools/bazel` wrapper also exposes them as
`bazel list config|trait|language`.

`App/` is generated, and is not checked in.

`TargetEmbed` needs `swift test --build-system native`: the default build
system in this toolchain generates nothing for `.embedInCode`, which is
SwiftPM's own gap rather than anything the package asks for — and the only
reason that rule has a package of its own. Its Bazel side is built the same
way as every other fixture.
