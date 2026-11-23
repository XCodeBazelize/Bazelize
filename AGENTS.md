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
- `config.bazelrc`, `traits.bazelrc`, and `languages.bazelrc` are generated and
  may be overwritten on every run.

Keep `.build/`, `Package.resolved`, `MODULE.bazel.lock`, `bazel-*`, and unrelated
root files intact. When changing regeneration behavior, cover both sides of the
contract: stale generated files disappear, while project-owned root files
survive repeated runs.
