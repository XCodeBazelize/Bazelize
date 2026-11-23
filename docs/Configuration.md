# Bazelize Configuration

## Status

This document defines the accepted `bazelize.yaml` v1 contract and records
possible v2 additions. The v2 section is a design backlog, not a compatibility
promise.

## Version 1

`bazelize config init` writes this file:

```yaml
schema: 1

buildifier:
  version: "10.1.0"
```

Generation reads it from the directory the input lives in, so that is where it
belongs. `-o` says where to write it: a directory to put `bazelize.yaml` in, or
the path of the file itself, defaulting to the current directory.

```sh
cd path/to/project && bazelize config init
bazelize config init -o path/to/project
bazelize config init -o config/custom.yaml   # then `generate --config-file`
```

Missing directories are created. An existing file is an error and is never
overwritten.

The buildifier release and optional cache defaults are configurable in v1. Bazel
and BCR dependency versions are generator-owned pins and MUST NOT be copied into
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

### Caches and local overrides

Existing schema-1 files continue to work. Add only the cache fields you need:

```yaml
cache:
  disk: ../cache/build
  repository: ../cache/downloads
  remote: https://cache.example.com
  upload-local-results: false
```

`--disk-cache`, `--repository-cache`, `--remote-cache`, and
`--remote-upload-local-results true|false` override their corresponding YAML
field independently. YAML paths are relative to the selected YAML file; CLI
paths are relative to the invocation directory. Paths are written as quoted
absolute rc arguments, including spaces, quotes, and backslashes. An empty
string disables a path or endpoint inherited from YAML. Remote endpoints use
HTTP(S) or gRPC(S); embedded username/password and control characters are rejected
before generation changes the output. Put authentication in user/CI settings,
never in the shared YAML or endpoint URL.

Every generation replaces `cache.bazelrc` from the current CLI/YAML values.
Omitting a CLI option on a later run does not retain its old generated value.
The project-owned `.bazelrc` keeps its unrelated lines; generated imports occur
once, followed by `try-import %workspace%/user.bazelrc`. The optional
`user.bazelrc` is never generated or overwritten. Ignore that file in version
control when it contains local paths or credentials.

Precedence for an ordinary build is generated settings, then `user.bazelrc`,
then flags passed directly to Bazel. For example:

```sh
bazelize --input Example.xcodeproj --output App \
  --disk-cache '/Users/me/Library/Caches/bazel outputs' \
  --remote-cache https://cache.example.com --remote-upload-local-results false
```

Disk cache stores action outputs, repository cache stores dependency downloads,
and remote cache shares action outputs across machines. Configure uploading
explicitly for your team; `false` consumes remote results without uploading local
results. When omitted, Bazel's own upload policy applies.

### Release catalog

`BazelDep+Buildifier.swift` is generated from `RepoSources.yml` by
`swift run RepoEnumGenerator` (also `make update-repo-enums`), and carries each
release's SHA-256 digests as GitHub's release API reports them.

A release is generated only when both hold:

- every host in `release_assets` has a SHA-256 digest in the GitHub release,
  so a generated lint command can run on any of them;
- the Bazel Central Registry serves that version of the module named in
  `RepoSources.yml`, so `latest` can never be a version `bazel_dep` cannot
  resolve.

A host is named the way `uname` names it: `os` is `uname -s` lowercased,
`machine` is `uname -m`. That is what the generated `lint.sh` switches on, and
adding a host is adding its asset to `RepoSources.yml`.

Every other generated dependency version already comes from the registry's
`metadata.json` with yanked versions removed. `Bazel` is the exception: it is
written to `.bazelversion` rather than requested as a module, so its versions
come from the repository's release tags.

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
