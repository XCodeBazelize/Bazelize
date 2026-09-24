# TODO

中文版：[TODO.zh-Hant.md](TODO.zh-Hant.md)

What the SwiftPM side of bazelize does not do yet, and why. Written after the
`spm/` fixture corpus reached 24 packages, all of which build and test both
ways (`swift build`/`swift test` and `bazelize` + `bazel test //...`).

Ordered by what a user would hit first.

## A. Generator behaviour

### A1. An executable target's resources are not bundled

A program built by `swift_binary` gets the generated `Bundle.module` accessor
and no bundle: `apple_resource_bundle` hands its resources to whatever bundles
them — an app or a test — and a program is neither, so the rule produces
something nothing puts anywhere. The binary compiles and `fatalError`s when it
runs.

`cquery --output=files` on such a bundle is empty, and its `OutputGroupInfo` is
an empty depset, so `data = [":XResources"]` on the binary brings nothing into
runfiles either.

Today the generator says so out loud while generating (`SwiftPM+Resources.swift`,
the `.executable` case) rather than leaving it to be found by a crash.

A fix means writing the bundle directory into the generated workspace —
`Generated/<Package>_<Target>.bundle` with the Info.plist and one link per
resource — carrying it as `data`, and teaching the accessor the runfiles
candidates. The cost is that `.process` no longer compiles: an asset catalogue,
a xib or a shader in a program's resources would be copied rather than built,
which is a divergence from SwiftPM worth reporting where it happens.

SwiftPM writes that bundle beside the program, so a package shipping a CLI tool
with resources works there and not here.

### A2. An undeclared privacy manifest is not bundled

`PrivacyInfo.xcprivacy` sitting beside a target's sources is bundled by
SwiftPM's default build system and by nothing here — the generator's discovered
resource types do not include it. A package that declares it (`.copy`) works
either way, which is what `spm/TargetResource` does.

Adding `xcprivacy` to the discovered types would match the default build
system, and diverge from `--build-system native`, which ignores it. Decide
which one is the contract before changing it.

### A3. A resource bundle is flat, not wrapped — not planned

On macOS SwiftPM produces `Bundle.bundle/Contents/Resources/…`; rules_apple
produces a flat `Bundle.bundle/…` on every platform by design, which is the iOS
shape. Measured: `Bundle.module.infoDictionary` and every `url(forResource:)`
lookup answer the same on both, and only code that builds `Contents/Resources`
paths by hand would notice. Aligning means not using `apple_resource_bundle`
and assembling the bundle ourselves, which is not worth it.

## B. Coverage

### B1. Nothing in `spm/` is built for iOS

Every fixture is macOS. `spm/Platform` declares `.iOS(.v16)` but its tests run
on macOS, so the iOS bundle shape, `minimum_os_version` on an iOS rule and the
platform transition a package rule is built through are covered only by
`fixture/iOS`, which is the Xcode side. This is the largest hole.

### B2. `.xcmappingmodel` — not planned

Its source is a Core Data XML persistent store that only Xcode's modeler
writes; a hand-written `xcmapping.xml` is rejected by `mapc` (`Unknown store
type, format, or version`), and there is no sample on a machine with Xcode
installed to copy the format from. Nothing about it is particular to bazelize
either: it is globbed and grouped exactly as `.xcdatamodeld` is, which is built
and asserted, and what would compile it is rules_apple's own action.

What migration is actually built on — a versioned `.xcdatamodeld` with both
versions in the bundle and a mapping derivable between them — is covered.

### B3. A dependency pinned by branch, revision or exact version

Every fixture uses `from:`. For the generator these are the same path: SwiftPM
resolves them and the generator reads the checkout. Low value.

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

### B7. Asset catalogue variants

Only a colour set is built. An app icon set, a symbol set and the generated
asset symbols are not.

## C. Process

### C1. Sub-packages have no tests — by design

Eleven packages under the fixtures (`vendor-kit`, `Alt`, `Other`, `Stamping`,
`Products`, `Trait/Dependency`, `TraitGraph/*Dependency`,
`DependencyCondition/Extras`, `DependencyCondition/LinuxOnly`) are dependencies
with nothing of their own to assert. CI builds every one of them and runs
`swift test` only where a `Tests` directory exists, rather than padding them
with tests that prove nothing.

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

### C3. `TargetEmbed` needs `--build-system native`

`.embedInCode` generates no `PackageResources` under the default build system
in this toolchain, which is SwiftPM's own gap. It is the only fixture that
needs the flag, which is why that rule has a package of its own.
