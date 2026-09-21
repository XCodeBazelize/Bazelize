# SwiftPM fixtures

One package per thing SwiftPM can do, named after the thing. Each is small
enough to read in a minute, and each one's tests only pass if bazelize
generated that thing correctly — a package that builds but asserts nothing
would not tell us anything.

| package | what it holds bazelize to |
|---|---|
| `BuildToolPlugin` | a build tool plugin and the tool it runs: the test target only compiles through a source the plugin generates |
| `CommandPlugin` | a plugin that is run on demand rather than while building, which nothing in a build may try to run |
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
```

`bazel run //:plugins` runs this workspace's build tool plugins and writes what
they generate into `Packages/<package>/Generated/`. It is a separate step
because a plugin is a program: Bazel builds it, and bazelize runs it as SwiftPM
would. `bazelize` has to be on `PATH` for that step.

`App/` is generated, and is not checked in.
