# TODO

中文版：[TODO.zh-Hant.md](TODO.zh-Hant.md)

What the SwiftPM side of bazelize does not do yet, and why. The fixture corpus
builds, tests, and runs the supported package shapes through both SwiftPM and
the generated Bazel workspace.

Ordered by what a user would hit first.

## A. Generator behaviour

### A1. Executable target resources — done

An executable now gets a real runfiles bundle rather than only a generated
`Bundle.module` accessor. `macos_bundle` performs the same platform processing
needed by asset catalogues, xibs, shaders, and other `.process` inputs; the
generated `//Packages:swiftpm_resource_bundle.bzl` rule extracts its archive as
a tree artifact, removes the bundler's empty executable and stale signature,
and exposes the resource-only `.bundle` through `DefaultInfo` runfiles.

The `swift_binary` carries that target as `data`. Its accessor checks the normal
Apple bundle locations first, then Bazel's `RUNFILES_DIR`, `TEST_SRCDIR`, and
the executable's sibling runfiles tree. `spm/ExecutableResource` runs the
result and checks copied and processed files, a compiled asset catalogue, and
an undeclared privacy manifest.

### A2. Undeclared privacy manifests — done

`PrivacyInfo.xcprivacy` in a target's source tree now receives `.copy`
semantics when no declared resource already owns it. The manifest therefore
lands under its own name at the bundle root, matching SwiftPM's default build
system without duplicating an explicit file or directory declaration.

`spm/ExecutableResource` covers the undeclared case;
`spm/TargetResource` keeps its explicit `.copy` declaration and covers the
deduplication path. This intentionally differs from `--build-system native`,
which ignores an undeclared manifest.

### A3. Not fixing for now: a resource bundle is flat, not wrapped

On macOS SwiftPM produces library and test resource bundles as
`Bundle.bundle/Contents/Resources/…`; rules_apple produces a flat
`Bundle.bundle/…` on every platform by design, which is the iOS shape.
Measured: `Bundle.module.infoDictionary` and every `url(forResource:)` lookup
answer the same on both, and only code that builds `Contents/Resources` paths
by hand would notice. Aligning those bundle shapes means not using
`apple_resource_bundle` and assembling them ourselves, which is not worth it.

`Compare Resource Bundles` keeps that physical layout difference explicit, then
normalizes the resource root and compares the library and test bundles in both
directions. Other known metadata, mode, and compiler-output differences are
individually named in `.github/scripts/bundle-differences.json`; an unlisted or
stale difference fails CI.

### A4. Not fixing for now: a dynamic library product becomes an ordinary library

The manifest still carries `{"library": ["dynamic"]}`, but `PackageProduct.kind`
collapses every library product to `.library`. The generated product is
therefore the same alias or `swift_library_group` as an automatic library, with
no note that SwiftPM was asked to vend a dynamic library.

No complete mapping has been chosen for the dylib-producing rule, product
facade, transitive linking, and packaging behaviour. Partial handling would
still leave the product contract unclear, so this remains documented and is
not scheduled.

### A5. A build tool plugin's executable reads its resources — done, one case open

`bazel run //:plugins` carries each tool's resource bundle in the runner's
runfiles, and the tool's `Bundle.module` accessor finds it there. Measured from
a clean generated workspace with a tool that fails unless it reads its
resource.

One case is still wrong, issue #81: a path listed in both `exclude` and
`resources` is a resource to SwiftPM and excluded here, so the target gets no
bundle and no accessor. `spm/BuildToolPlugin`'s tool is declared that way and
never reads its resources, which is why the fixture does not notice.

### A6. Not fixing for now: configuration cannot select targets or disable generated features

The v1 `bazelize.yaml` schema configures the buildifier release and cache defaults.
Someone who must leave a target out cannot express that without forking the
input project or the generator.

The conservative target-selection contract is exact target names and an error
when an included target depends on an excluded one. Feature switches should be
added only for generated surfaces with a demonstrated cost or incompatibility;
keys name user-visible capabilities rather than internal plugin classes.
Bazel/BCR dependency pins remain generator-owned, and Swift package versions
remain owned by `Package.resolved`.

### A7. Trait selection already matches SwiftPM — done

SwiftPM's `--traits A` compiles that package with `-DA`; another trait that is
not selected contributes no `-D` at all. That is what the generated
`--config=<Package>.A` does: it turns on A's build setting and leaves the
package's other trait conditions absent. A false build setting is not a
negative compiler definition.

The generated `<Package>.none` is the spelling for
`--disable-default-traits`; `<Package>.default` restores the manifest defaults,
and `<Package>.all` enables every trait. Several selected traits can be
expressed with the public boolean flags. The missing single-config shorthand is
only convenience, not a generator behaviour gap, so it is no longer tracked as
unfinished work.

### A8. iOS and tvOS product types an app embeds — done, two cases open

An App Clip becomes an `ios_app_clip` its application carries in `app_clips`;
an iMessage extension an `ios_imessage_extension`; a sticker pack an
`ios_sticker_pack_extension` whose `sticker_assets` is its catalog; a tvOS app
extension a `tvos_extension` its `tvos_application` carries in `extensions`; an
iMessage app an `ios_imessage_application` around the one extension it holds.
`fixture/iOS` builds `ProductKinds` and `TVProductKinds` with both Xcode and the
generated workspace, and CI checks that the clip and the extensions land where
Xcode puts them.

What is still open:

- **A sticker pack inside an ordinary app is left out of it.** Xcode embeds one
  in any app's `PlugIns`; rules_apple's `ios_application.extensions` accepts only
  `IosExtensionBundleInfo`, which `ios_sticker_pack_extension` does not provide.
  The generator writes the sticker pack's own rule and says so in a note;
  `ProductKinds` is the case that prints it.
- **An iMessage app has no fixture.** Tuist has no product for
  `com.apple.product-type.application.messages`. It was verified by hand: a
  Tuist project whose target was retyped in `project.pbxproj` and stripped of
  sources builds with `xcodebuild`, and its generated `ios_imessage_application`
  builds with Bazel into the same layout — the extension in `PlugIns` and the
  stub executable. Nothing in CI repeats that.

### A9. Embedded watchOS apps and extensions — done, container open

A single-target watch app becomes `watchos_application` with its code in `deps`
and app extensions in `extensions`. A source-free watchOS 2 app uses the same
rule with its WatchKit extension in `extension`; that extension becomes
`watchos_extension`. A watchOS app extension, including
`com.apple.product-type.app-extension.intents-service`, uses
`watchos_extension(application_extension = True)`. An iOS companion embeds
either watch app through `ios_application.watch_application`.

`fixture/iOS` has `WatchCompanion` with an Intents service and `Watch2Companion`
with a WatchKit extension. The fixture preparation script retypes the Intents
target because Tuist has no Intents service product. Xcode and Bazel build both
shapes; CI checks the nested executables and the watchOS 2 stub under `Watch/`.
The Intents service product on iOS remains an error: Xcode 27 does not resolve
that product type for iOS either.

**A watch-only iOS container (`watch2AppContainer`) is not generated.** Xcode
copies its platform's `MessagesApplicationStub` into the container rather than
linking an executable. The generated `ios_application` failed to link with an
undefined `_main`; it cannot faithfully reproduce that stub packaging. The
generator emits a note and still generates the contained watch app, which can
be built independently. This container has no CI fixture; its Xcode build and
the Bazel link failure were verified manually. Support needs a rule that
bundles the platform stub, not a fabricated `main`.

## B. Coverage

### B1. Root-package tests run on macOS and iOS Simulator — done

Each root-package test target now has platform-compatible macOS and iOS
Simulator bundle variants. `bazel test //...` keeps the existing macOS target
and label; `--platforms=@apple_support//platforms:ios_sim_arm64` skips it and
runs the iOS variant. `spm/Platform` proves the simulator execution reaches an
iOS-only dependency and reads a test resource through `Bundle.module`.

The tvOS and watchOS Simulator variants run through the generated runner. The
visionOS Simulator variant and every device variant are built and not
executed, and Mac Catalyst is unavailable upstream; `docs/SPM.md` and the
comments beside the lane in `.github/workflows/swift.yml` say why for each.

### B2. `.xcmappingmodel` — not planned

Its source is a Core Data XML persistent store that only Xcode's modeler
writes; a hand-written `xcmapping.xml` is rejected by `mapc` (`Unknown store
type, format, or version`), and there is no sample on a machine with Xcode
installed to copy the format from. Nothing about it is particular to bazelize
either: it is globbed and grouped exactly as `.xcdatamodeld` is, which is built
and asserted, and what would compile it is rules_apple's own action.

What migration is actually built on — a versioned `.xcdatamodeld` with both
versions in the bundle and a mapping derivable between them — is covered.

### B4. A package with no products, and a plugin-only package — done

Neither needed a lane of its own. `spm/TargetExclude` declares no products at
all — a package that is nothing but targets, built and tested and depended on
by nothing — and `spm/PluginDependency/Marking` is nothing but a plugin and the
plugin product that shares it, used by the package next door.

Worth knowing about the second: a plugin belonging to another package is
compiled by bazelize rather than built by Bazel. `Packages/Marking/BUILD` comes
out empty, because the rules that build a plugin are written for the package
that *uses* it, and Marking uses nothing. The empty file is deliberate: it
keeps the directory a Bazel package of its own, so the parent's globs do not
reach into it.

### B5. A bare source directory — done, and it was a gap rather than dead code

The fallback looked for `<package root>/<target name>`. SwiftPM warns about
that layout and builds an empty module from it — a target laid out that way
cannot be imported — so nothing valid ever reached the fallback.

What SwiftPM does allow, and what the fallback missed, is the source directory
*itself*: files in `Sources` with no directory of the target's own, which is
legal when no other target could claim them. Such a package was dropped
silently — an empty `BUILD` and no rule.

`sourceDirectory` looks there now, guarded by the same condition SwiftPM
applies: the package has one target of that kind. `spm/ConfigurationCondition`
is laid out that way, so something would notice.

### B6. A macro used from another package — done

`spm/Macro/Provider` ships a macro and the library that declares it; the root
package uses that macro through the product, beside the macro of its own it
already used.

Nothing in the generator needed changing, which is the thing worth knowing: the
consumer's rule lists only its own package's plugin, and the one a package away
arrives because the library that declares the macro carries
`plugins = [":ProviderMacros"]` and rules_swift propagates a compiler plugin to
whoever depends on that library — through the product facade included.

### B7. Asset catalogue variants — done

The iOS fixture now builds its app icon and a custom symbol set. It also enables
Xcode's generated Swift asset symbols and compiles source references to the
generated image, symbol-image, and colour APIs. The built IPA carries
`Assets.car` and app-icon metadata.

### B8. Plugin rules named the generating machine's toolchain — done

A generated plugin `BUILD` carried the absolute path of the Swift toolchain's
`PluginAPI` directory, found with `xcrun` while generating: the workspace was
specific to one Xcode installation, and no plugin fixture could be recorded as
a snapshot. The rules now name that directory the way the tools running the
build name it — `__BAZEL_SWIFT_TOOLCHAIN_PATH__` in `copts`, which
`rules_swift`'s worker resolves to the toolchain of the action, and
`__BAZEL_XCODE_DEVELOPER_DIR__` in `linkopts`, which `apple_support`'s
`wrapped_clang` resolves to `DEVELOPER_DIR`. Generation asks `xcrun` nothing,
and `Tests/Snapshots/BuildToolPlugin` records the rules verbatim.

## C. Process

### C1. Sub-packages have no tests — by design

Fixtures with no tests are not padded with assertions that prove nothing. On
the Bazel side, CI asks `bazel query 'tests(//...)'` before invoking
`bazel test //...`; executable-only packages such as `spm/ExecutableResource`
are built and run by their dedicated program step without turning an empty test
selection into a lane failure.

Thirteen sub-packages (`vendor-kit`, `Alt`, `Other`, `Stamping`, `Marking`,
`Products`, `Macro/Provider`, `Trait/Dependency`, `TraitGraph/*Dependency`,
`DependencyCondition/Extras`, `DependencyCondition/LinuxOnly`) likewise have
nothing of their own to assert.

The SwiftPM side asks the manifest rather than the directory tree: the lane
reads `swift package dump-package` to decide whether a package has anything to
build and whether it has a test target. `spm/TargetPath` keeps its tests in
`Code/Tests`, and they run on both sides.

### C2. A lane fails on a note no fixture expects — done

A note is the generator saying the build differs from what the package asked
for: a plugin that did not run, a program whose resources nothing can bundle, a
library `pkg-config` has never heard of. Every one of those builds and tests
green and is wrong at run time, and the package lanes threw the generator's
output away.

They now keep it and fail on anything said, unless the lane names the note it
is there for in `notes`. No fixture says anything today, so the gate starts
shut: a note that appears is a lane turning red, rather than a line nobody
reads.

### C3. `TargetEmbed` is run with `--build-system native`

On the toolchain that lane was written against, `swiftbuild` generated no
`PackageResources` for `.embedInCode` at all — Xcode 27's does — while `native`
has generated it all along. The lane names the build system that implements the
rule rather than inheriting whichever the runner ships, which is why that rule
has a package of its own.

### C4. Generated Starlark lint gates CI — done

`GeneratedStarlarkLint` generates every local fixture and runs two commands in
each workspace, with no build and no test. `//:lint` reports every buildifier
warning and does not fail the job. `//:lint-ci` fails it on the reviewed
categories that change behaviour or leave a workspace unloadable. Format-only
`# reformat` reports stay visible and do not fail.

### C5. Not planned: generation opting into formatting

The current contract is explicit formatting with `bazel run //:format`;
generation itself does not format. If generation gets an opt-in, decide between
a `--format` flag and a persistent configuration key. It must invoke the
workspace's `//:format`, which downloads the configured buildifier release and
verifies its checksum, rather than using an arbitrary executable from `PATH`.

Adopting formatted generated output requires re-recording every generated
workspace snapshot. Only after that can the lint gate reject format differences
as well as lint warnings.

Issue #48 proposed the opt-in and was closed as not planned.
