# Repository Instructions

## Change delivery

Any new feature or behavior change goes on its own branch and is delivered as a
pull request. Never push such work directly to `master`.

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
