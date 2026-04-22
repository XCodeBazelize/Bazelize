# Roadmap Command Design

## Goal

Add a new CLI command that materializes the tree described in `docs/Roadmap.md` from an Xcode project into an output directory.

The first milestone is intentionally narrow:

- create the output directory tree
- create per-target `Sources/` and `Generated/` directories
- create the root `Prebuilt/` directory
- create symlinks for target-owned filesystem entries
- create empty `BUILD` files as placeholders

This milestone does not generate Bazel rules yet.

## Scope

Command shape:

```bash
bazelize roadmap --project fixture/iOS2/Example.xcodeproj --output fixture/iOS2_O
```

Inputs:

- `--project`: path to the `.xcodeproj`
- `--output`: path to the output root
- optional `-c/--config`: preferred config name, reused from `xcode2`

Outputs:

- `$Output/BUILD`
- `$Output/MODULE.bazel`
- `$Output/Prebuilt/BUILD`
- `$Output/Targets/$Target/BUILD`
- `$Output/Targets/$Target/Sources/...`
- `$Output/Targets/$Target/Generated/`

## Path Rules

The command follows the existing roadmap rules:

- emitted paths are based on filesystem paths relative to the `.xcodeproj` root
- Xcode logical groups do not affect output layout
- source files, headers, resources, localized files, and other target-owned filesystem entries all go under `Sources/`
- directory entries are symlinked as directories and are not flattened
- target metadata stays in Bazel files and is not emitted as standalone files in the tree
- `Generated/` is target-local
- `Prebuilt/` is global at the root

## Minimal Behavior

For each target from `XCode.Project.targets`:

1. create `Targets/<Target>/`
2. create `Targets/<Target>/Sources/`
3. create `Targets/<Target>/Generated/`
4. create an empty `Targets/<Target>/BUILD`
5. collect file entries from the target model
6. map each entry to a path relative to the project root
7. create parent directories under `Sources/`
8. create a symlink at the destination path pointing to the source path

For root output:

1. create output root
2. create empty root `BUILD`
3. create empty `MODULE.bazel`
4. create `Prebuilt/`
5. create empty `Prebuilt/BUILD`

## File Selection

The initial version should use the target file model already exposed by `XCode2`:

- `target.files.sources`
- `target.files.headers`
- `target.files.resources`
- `target.files.others`

Framework and copy-files entries should be excluded from `Sources/` for this first milestone because they are closer to dependency packaging than target-owned source tree materialization. Prebuilt binary handling stays reserved for a later increment.

## Failure Handling

This milestone keeps failure handling simple:

- if an entry has no usable relative path, skip it
- if the source path does not exist, skip it for now
- if the destination already exists, replace it

The roadmap already marks missing-file behavior as deferred, so this implementation should stay minimal and deterministic rather than complete.

## Architecture

Keep the command thin and move tree generation into a small reusable builder.

- `RoadmapCommand` parses CLI arguments and loads `XCode.Project`
- `RoadmapTreeBuilder` creates directories and symlinks
- tests cover the builder output using the `fixture/iOS2` project

## Testing

Add a focused integration-style unit test that:

1. loads `fixture/iOS2/Example.xcodeproj`
2. writes output into a temporary directory
3. verifies expected directories exist
4. verifies expected `BUILD` placeholders exist
5. verifies representative symlinks exist and point to the expected source paths

## Open Choices Resolved

- command name: `roadmap`
- output path: explicit `--output`
- generated files location: `Targets/<Target>/Generated`
- prebuilt binary location: root `Prebuilt/`
- source layout: preserve original relative paths from the project root
