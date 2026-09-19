# Roadmap Command Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `bazelize roadmap` command that creates the roadmap directory tree and target source symlinks for an Xcode project.

**Architecture:** The CLI command will parse `--project`, `--output`, and optional config, then load `Xcode.Project` and hand off to a small tree builder. The tree builder will create root placeholders, per-target directories, and symlink target-owned filesystem entries into `Sources/` while preserving relative paths from the project root.

**Tech Stack:** Swift, Swift Argument Parser, PathKit, XCTest

---

### Task 1: Lock down the expected output tree with a failing test

**Files:**
- Create: `Tests/Xcode2Tests/RoadmapTreeBuilderTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
func testBuildCreatesTargetTreeAndSymlinks() throws {
    let projectPath = Path.current + "fixture/iOS2/Example.xcodeproj"
    let project = try Xcode.Project.load(path: projectPath, preferConfig: nil)
    let output = Path(NSTemporaryDirectory()) + UUID().uuidString

    try Xcode.RoadmapTreeBuilder(output: output).build(project: project)

    XCTAssertTrue((output + "Targets/Example/Sources").exists)
    XCTAssertTrue((output + "Targets/Example/Generated").exists)
    XCTAssertTrue((output + "Targets/Example/BUILD").exists)
    XCTAssertTrue((output + "Prebuilt/BUILD").exists)
    XCTAssertEqual(try (output + "Targets/Example/Sources/Example/ExampleApp.swift").symlinkDestination(), projectPath.parent() + "Example/ExampleApp.swift")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter RoadmapTreeBuilderTests/testBuildCreatesTargetTreeAndSymlinks`
Expected: FAIL because `RoadmapTreeBuilder` does not exist yet.

### Task 2: Implement the tree builder

**Files:**
- Create: `Sources/Xcode2/RoadmapTreeBuilder.swift`

- [ ] **Step 1: Add a minimal tree builder**

```swift
public extension Xcode {
    struct RoadmapTreeBuilder {
        let output: Path

        public func build(project: Xcode.Project) throws {
            // create root placeholders
            // create target directories
            // create symlinks
        }
    }
}
```

- [ ] **Step 2: Materialize root placeholders**

Run builder code that creates:

```text
BUILD
MODULE.bazel
Prebuilt/
Prebuilt/BUILD
```

- [ ] **Step 3: Materialize target tree and symlinks**

Run builder code that creates:

```text
Targets/<Target>/BUILD
Targets/<Target>/Sources/
Targets/<Target>/Generated/
```

and symlinks target `sources`, `headers`, `resources`, and `others` entries using project-root-relative paths.

- [ ] **Step 4: Run the focused test to verify green**

Run: `swift test --filter RoadmapTreeBuilderTests/testBuildCreatesTargetTreeAndSymlinks`
Expected: PASS

### Task 3: Wire the CLI command

**Files:**
- Modify: `Sources/Bazelize/Command.swift`

- [ ] **Step 1: Add the new command type**

```swift
struct RoadmapCommand: AsyncParsableCommand {
    @Option var project: String
    @Option var output: String
    @Option var config: String?
}
```

- [ ] **Step 2: Register it in the root command**

Add `RoadmapCommand.self` to `subcommands`.

- [ ] **Step 3: Call the builder**

```swift
let dump = try Xcode.Project.load(path: path, preferConfig: config)
try Xcode.RoadmapTreeBuilder(output: Path.current + output).build(project: dump)
```

- [ ] **Step 4: Re-run the focused test**

Run: `swift test --filter RoadmapTreeBuilderTests`
Expected: PASS

### Task 4: Verify the CLI end to end

**Files:**
- Modify: `Sources/Bazelize/Command.swift`

- [ ] **Step 1: Run the test suite for the new builder**

Run: `swift test --filter RoadmapTreeBuilderTests`
Expected: PASS

- [ ] **Step 2: Run the command against the fixture**

Run: `swift run bazelize roadmap --project fixture/iOS2/Example.xcodeproj --output fixture/iOS2_O`
Expected: creates `fixture/iOS2_O/Targets/Example/Sources`, `fixture/iOS2_O/Targets/Example/Generated`, root `Prebuilt`, and representative source symlinks.
