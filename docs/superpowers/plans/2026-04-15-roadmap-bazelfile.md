# Roadmap Bazel File Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the roadmap output generate package-shaped Bazel files that move `fixture/iOS2/Example.xcodeproj` toward `bazel run //Example:Example`.

**Architecture:** Extend `RoadmapTreeBuilder` so it owns both filesystem materialization and minimal Bazel file generation. The builder will emit root files (`BUILD`, `MODULE.bazel`, `Package.swift`) and one package `BUILD` per target using lightweight string templates driven by the `XCode2` model.

**Tech Stack:** Swift, PathKit, XCTest

---

### Task 1: Lock down package-shaped output and BUILD content with a failing test

**Files:**
- Modify: `Tests/XCode2Tests/RoadmapTreeBuilderTests.swift`

- [ ] **Step 1: Add assertions for package layout and BUILD text**

```swift
XCTAssertTrue((output + "Example/Sources").exists)
XCTAssertTrue((output + "Example/BUILD").exists)
XCTAssertTrue(try (output + "Example/BUILD").read().contains("ios_application("))
XCTAssertTrue(try (output + "Example/BUILD").read().contains("name = \"Example\""))
XCTAssertTrue(try (output + "Static2/BUILD").read().contains("objc_library("))
XCTAssertTrue(try (output + "MODULE.bazel").read().contains("rules_swift_package_manager"))
```

- [ ] **Step 2: Run the focused test to verify it fails**

Run: `swift test --filter RoadmapTreeBuilderTests/testBuildCreatesTargetTreeAndSymlinks`
Expected: FAIL because the current builder still writes `Targets/<name>` and empty placeholders.

### Task 2: Switch to package-shaped filesystem output

**Files:**
- Modify: `Sources/Xcode2/RoadmapTreeBuilder.swift`

- [ ] **Step 1: Change target output root**

Update:

```swift
let targetRoot = output + target.name
```

instead of `output + "Targets" + target.name`.

- [ ] **Step 2: Re-run the focused test**

Run: `swift test --filter RoadmapTreeBuilderTests/testBuildCreatesTargetTreeAndSymlinks`
Expected: FAIL on missing BUILD contents rather than wrong directory layout.

### Task 3: Generate minimal BUILD and module files

**Files:**
- Modify: `Sources/Xcode2/RoadmapTreeBuilder.swift`

- [ ] **Step 1: Generate root `MODULE.bazel` and `Package.swift`**

Add code that writes:

```python
module(name = "example", version = "0.0.1")
```

plus bazel deps and SwiftPM extension wiring.

- [ ] **Step 2: Generate package BUILD content**

Implement minimal generation for:

- `ios_application`
- `ios_framework`
- `swift_library`
- `objc_library`
- `alias`

- [ ] **Step 3: Wire target and SwiftPM dependencies**

Generate labels from:

- `target.dependencies.targets`
- `target.dependencies.packageProducts`
- `target.dependencies.sdkFrameworks`

- [ ] **Step 4: Re-run the focused test**

Run: `swift test --filter RoadmapTreeBuilderTests/testBuildCreatesTargetTreeAndSymlinks`
Expected: PASS

### Task 4: Verify the new Bazel file output

**Files:**
- Modify: `Tests/XCode2Tests/RoadmapTreeBuilderTests.swift`

- [ ] **Step 1: Run the builder test suite**

Run: `swift test --filter RoadmapTreeBuilderTests`
Expected: PASS

- [ ] **Step 2: Run the roadmap command against the fixture**

Run: `swift run bazelize roadmap --project fixture/iOS2/Example.xcodeproj --output fixture/iOS2_O`
Expected: package-shaped output such as `fixture/iOS2_O/Example/BUILD` and `fixture/iOS2_O/Framework1/BUILD`.
