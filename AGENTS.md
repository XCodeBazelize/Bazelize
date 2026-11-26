# Repository Instructions

## Change delivery

Any new feature or behavior change goes on its own branch and is delivered as a
pull request. Never push such work directly to `master`.

Open an issue before implementing a change. Prefer one issue and one pull request
for each independently deliverable change. This is a default, not an absolute
constraint: when splitting or combining work is necessary, explain why and link
all affected issues and pull requests so their scope and completion remain clear.

A branch is cut from the current `master` before the first edit, and the pull
request names the issue it settles with a closing keyword — `Closes #44` — so
merging the pull request closes it. Work that only investigates an issue, or
that changes the issue's own description, uses `Refs #44` instead: an
investigation is not a fix.

## Swift code style

Use nicklockwood/SwiftFormat, pinned in `mise.toml`, with the repository's
`.swiftformat` rules. Run `make format` before committing changed Swift files,
then review and stage the intended changes. Before opening a PR, also format
files changed since its base with
`python3 scripts/format-swift.py --base origin/master` (use the actual base).
Install the local staged-content check with `make install-hooks`. It never
rewrites the index or working tree. Do not run SwiftFormat in CI or as a build
dependency. Preserve fixture compatibility with each manifest's Swift version.

Prefer declarative path definitions. Initialize a path owned by an object in
its initializer, or store the root and expose fixed derived paths as computed
properties. This applies to tests too: avoid a temporary `destination` local
whose only purpose is `root + "config/custom.yaml"`; give that location a named
property on the fixture instead. Keep local values when they represent a real
intermediate result or a runtime choice.

```swift
init(_ root: Path) {
    path = root + "config.bazelrc"
}

var foo: Path { root + "Foo" }
```

Declare external command operations as purpose-named static methods in
extensions of an `enum Commands { }` namespace in the owning module. Callers
should express intent, such as `Commands.showSDK(sdk:)`, and receive a useful
result type, such as `Path`, parsed values, or `Void`, rather than assemble
executable names and argument arrays at each callsite. Command methods own
argument construction, working directories, output capture, and exit-status
handling; use `async throws` for asynchronous operations that can fail.

Swift child-process execution MUST consistently use `swift-subprocess`
(`Subprocess.run`). Do not introduce parallel execution paths through
`Foundation.Process`, hand-managed `Pipe` instances, or other process-launch
APIs. Keep any shared execution helper behind the semantic command methods.
Group operations in `Commands`; do not build a full wrapper type or framework
for every CLI.

## Issue language

Every issue this repository files carries both English and 中文, in that order,
separated by `---`. Both halves say the same thing: the same problem, the same
proposed direction, and the same acceptance criteria. A reader of either
language gets the whole issue, never a summary of the other half.

Each issue states what is observably wrong, the direction a fix would take, and
the acceptance criteria that decide when it is done. An acceptance criterion
names behavior that can be run, not the shape of the code that produces it.

## Generated workspace ownership

Bazelize preserves the workspace root. Never replace or delete it wholesale:
SwiftPM and Bazel keep resolved state there, and users may keep project-owned
configuration beside the generated files.

Each generation run fully rebuilds these generator-owned subtrees:

- `Targets/`
- `Prebuilt/`
- `Packages/`

Do not preserve hand-written files inside those directories. Rebuilding
`Packages/` is required: a stale `BUILD` left by a dependency or target that
left the resolved SwiftPM graph remains part of `bazel build //...`.

The root rc files have distinct ownership:

- `.bazelrc` is project-owned. Preserve its existing content and ensure each
  generated import occurs exactly once.
- `config.bazelrc`, `traits.bazelrc`, `languages.bazelrc`, and `cache.bazelrc`
  are generated and may be overwritten on every run.
- `user.bazelrc` is user-owned and optional. Preserve it and ensure its
  `try-import` occurs once after the generated imports so local overrides win.

Keep `.build/`, `Package.resolved`, `MODULE.bazel.lock`, `bazel-*`, and unrelated
root files intact. When changing regeneration behavior, cover both sides of the
contract: stale generated files disappear, while project-owned root files
survive repeated runs.
