# Bazelize Configuration

## Status

This document defines the accepted `bazelize.yaml` v1 contract and records
possible v2 additions. The v2 section is a design backlog, not a compatibility
promise.

## Version 1

`bazelize init` writes this file:

```yaml
schema: 1

buildifier:
  version: "10.1.0"
```

With no argument, `init` writes to the current directory. An optional directory
selects another destination:

```sh
bazelize init
bazelize init path/to/project
```

Missing destination directories are created. An existing `bazelize.yaml` is an
error and is never overwritten.

Only the buildifier release is configurable in v1. Bazel and BCR dependency
versions are generator-owned pins and MUST NOT be copied into
`bazelize.yaml`.

### Selection

`bazelize generate` selects exactly one configuration source, in this order:

1. the path passed to `--config-file`;
2. `bazelize.yaml` beside the input `.xcodeproj`, or in the Swift package root;
3. Bazelize's compiled defaults.

An explicit path that is missing or invalid is an error. Bazelize does not
merge an explicit file with an automatically discovered file.

### Validation

- `schema` is required and MUST be `1`.
- Unknown properties are errors.
- `buildifier.version` is required.
- A buildifier version MUST exist in Bazelize's release catalog because the
  catalog owns the platform checksums used by generated lint commands.

### Deliberate omissions

- Xcode configuration stays on the `-c` command-line option.
- Features that are always generated today stay enabled.
- Target selection is not configurable.
- Generation never formats source or generated files automatically.

## Possible Version 2 Additions

These candidates require concrete use cases and migration semantics before
acceptance.

### Target selection

```yaml
targets:
  exclude:
    - LegacyApp
```

Open contract questions:

- whether names are exact Xcode target names or patterns;
- whether excluding a dependency also excludes its dependants or fails;
- how Swift package products and generated plugin targets are addressed.

Exact names plus a dependency error are the conservative default.

### Feature switches

```yaml
features:
  lint: true
  xcodeproj: true
```

A switch is justified only when disabling the generated surface removes real
cost or incompatibility. Keys should describe user-visible capabilities, not
internal plugin class names.

### Buildifier policy

```yaml
buildifier:
  version: "10.1.0"
  warnings: all
```

`warnings` could control the warning set passed by `//:lint`. Automatic
formatting remains out of scope; formatting should be an explicit command.

## Non-goals for Version 2

The following should remain outside the file unless their ownership model
changes:

- Bazel, `rules_*`, and other BCR dependency pins;
- Swift package versions, which come from `Package.resolved`;
- Xcode build configuration selection;
- arbitrary Starlark or shell injection;
- internal generator plugin names.
