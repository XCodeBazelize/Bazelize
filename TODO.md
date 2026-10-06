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

### A4. Not fixing for now: a dynamic library product becomes an ordinary library

The manifest still carries `{"library": ["dynamic"]}`, but `PackageProduct.kind`
collapses every library product to `.library`. The generated product is
therefore the same alias or `swift_library_group` as an automatic library, with
no note that SwiftPM was asked to vend a dynamic library.

No complete mapping has been chosen for the dylib-producing rule, product
facade, transitive linking, and packaging behaviour. Partial handling would
still leave the product contract unclear, so this remains documented and is
not scheduled.

### A5. Undecided: a build tool plugin's executable loses its resource runfiles

`//Packages:plugins` is a `filegroup` whose `srcs` are the plugin tool binaries.
It does not forward the runfiles of those binaries. A tool with resources can
compile and be found by the plugin host, then fail when it tries to load its
bundle at run time.

The plugin entry point and the runfiles it needs must travel together, but the
provider shape and fixture contract have not been chosen. Leave this undecided
rather than committing to a custom forwarding rule prematurely.

### A6. Not fixing for now: configuration cannot select targets or disable generated features

The v1 `bazelize.yaml` schema has only `schema` and the buildifier release.
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

## B. Coverage

### B1. Nothing in `spm/` is *tested* on iOS

`spm/Platform` is now built for iOS: its lane compiles the package rule through
`--platforms=@apple_support//platforms:ios_sim_arm64` and asserts which
settings and dependencies that configuration selects. What is still macOS-only
is everything that needs a bundle to exist — the iOS bundle shape and
`minimum_os_version` on an iOS rule — because a package's tests are a
`macos_unit_test`. Running a fixture's tests on a simulator is the remaining
hole.

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

### B8. Plugin output cannot be recorded in workspace snapshots

A generated plugin `BUILD` contains an absolute path into the active Swift
toolchain. Recording it verbatim would make the snapshot specific to one
machine and Xcode installation. Mask that path in the snapshot harness before
adding a plugin workspace to `GeneratedWorkspaceSnapshotTests`.

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

One SwiftPM-side gap remains: the directory check misses a package that
declares a custom test target path. `spm/TargetPath` keeps its tests in
`Code/Tests`, so its SwiftPM tests have never run in this lane even though the
Bazel side does. Use `swift package dump-package` to ask whether the manifest
has a test target instead of assuming a top-level `Tests` directory.

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

### C4. Generated Starlark lint does not gate CI

Both `Check Generated Starlark` steps run `bazel run //:lint` with
`continue-on-error: true`, so a new lint warning is reported and ignored. Move
this to a cheap lane that does only `generate` then `lint` for each fixture —
no build and no test — and remove the duplicate checks from the expensive
integration lanes. The first gate blocks lint warnings but continues to allow
format-only `# reformat` reports.

### C5. Decide whether generation can opt into formatting

The current contract is explicit formatting with `bazel run //:format`;
generation itself does not format. If generation gets an opt-in, decide between
a `--format` flag and a persistent configuration key. It must invoke the
workspace's `//:format`, which downloads the configured buildifier release and
verifies its checksum, rather than using an arbitrary executable from `PATH`.

Adopting formatted generated output requires re-recording every generated
workspace snapshot. Only after that can the lint gate reject format differences
as well as lint warnings.
