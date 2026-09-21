# SwiftPM fixtures

One package per thing SwiftPM can do, named after the thing. Each is small
enough to read in a minute, and each one's tests only pass if bazelize
generated that thing correctly — a package that builds but asserts nothing
would not tell us anything.

| package | what it holds bazelize to |
|---|---|
| `BuildToolPlugin` | a build tool plugin and the tool it runs: the test target only compiles through a source the plugin generates |
| `Clang` | a C-family target: public headers somewhere of its own, a private header search path, defines with and without a value, C++ interoperability, and the bundle a C target reaches without importing anything |
| `CommandPlugin` | a plugin that is run on demand rather than while building, which nothing in a build may try to run |
| `DependencyCondition` | dependencies conditional on a platform and on a trait: what the condition excludes must not be built |
| `Macro` | a macro target, loaded by the compiler while the target beside it is compiled |
| `Trait` | the package's own traits, a default one, a dependency whose trait is turned on by name, and build settings conditional on each |
| `TargetSources` | `sources:`, where a file beside the listed ones must not be compiled |
| `TargetPath` | `path:`, where neither the target nor its tests are under `Sources/` |
| `TargetExclude` | `exclude:`, where a named file and a named directory must not be compiled |
| `TargetResource` | the three resource rules: `.copy`, `.process`, and `.embedInCode` |

A package that must not compile a file says so in the file: it is a
`#error(…)`, so a generator that globs too much fails loudly instead of
quietly passing.

## Running one

```sh
cd spm/<package>
bazelize --project . --output App
cd App
bazel run //:plugins   # only the packages with a build tool plugin need this
bazel test //...
bazel list config      # what `--config=<name>` the workspace defines
bazel list trait       # which traits its packages declare, and which are on
bazel test //... --config=<Package>.<Trait>   # …with one of them turned on
```

`bazel run //:plugins` runs this workspace's build tool plugins and writes what
they generate into `Packages/<package>/Generated/`. It is a separate step
because a plugin is a program: Bazel builds it, and bazelize runs it as SwiftPM
would.

`bazel list` is a command the generated `tools/bazel` adds, which Bazelisk runs
in Bazel's place. `bazelize` has to be on `PATH` for either.

`App/` is generated, and is not checked in.
