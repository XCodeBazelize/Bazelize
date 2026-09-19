# Xcode2 Print Target Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `--print-target <name>` option to `bazelize xcode2` that prints a human-readable summary for one target instead of the full project JSON dump.

**Architecture:** Keep JSON output as the default behavior. Move the new text rendering into a small formatter in the `Xcode2` module so it can be unit tested without invoking the executable target. The CLI command will only choose between JSON mode and summary mode.

**Tech Stack:** Swift, Swift Argument Parser, XCTest

---

### Task 1: Lock down the text output shape

**Files:**
- Create: `Tests/Xcode2Tests/TargetSummaryFormatterTests.swift`
- Modify: `Package.swift`

- [ ] **Step 1: Write the failing test**

```swift
func testFormatTargetSummary() throws {
    let summary = Xcode.TargetSummaryFormatter.format(project: project, target: target)

    XCTAssertTrue(summary.contains("Target: Example"))
    XCTAssertTrue(summary.contains("Type: com.apple.product-type.application"))
    XCTAssertTrue(summary.contains("Files:"))
    XCTAssertTrue(summary.contains("Settings [Release]:"))
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter TargetSummaryFormatterTests/testFormatTargetSummary`
Expected: FAIL because `TargetSummaryFormatter` and the `Xcode2Tests` target do not exist yet.

- [ ] **Step 3: Add the new test target**

```swift
.testTarget(
    name: "Xcode2Tests",
    dependencies: ["Xcode2"]
),
```

- [ ] **Step 4: Run test to verify it still fails for the right reason**

Run: `swift test --filter TargetSummaryFormatterTests/testFormatTargetSummary`
Expected: FAIL because the formatter symbol is still missing.

### Task 2: Implement formatter and CLI wiring

**Files:**
- Create: `Sources/Xcode2/TargetSummaryFormatter.swift`
- Modify: `Sources/Bazelize/Command.swift`

- [ ] **Step 1: Write minimal formatter implementation**

```swift
public enum TargetSummaryFormatter {
    public static func format(project: Xcode.Project, target: Xcode.Target) -> String {
        // build readable text sections
    }
}
```

- [ ] **Step 2: Wire command-line option**

```swift
@Option(name: [.customLong("print-target", withSingleDash: false)])
var printTarget: String?
```

- [ ] **Step 3: Select summary mode in the command**

```swift
if let printTarget {
    // find target and print formatted summary
} else {
    // existing JSON output
}
```

- [ ] **Step 4: Run tests to verify green**

Run: `swift test --filter TargetSummaryFormatterTests`
Expected: PASS

### Task 3: Verify the integrated behavior

**Files:**
- Modify: `Sources/Bazelize/Command.swift`

- [ ] **Step 1: Run the targeted test suite**

Run: `swift test --filter TargetSummaryFormatterTests`
Expected: PASS

- [ ] **Step 2: Run a CLI sanity check**

Run: `swift run bazelize xcode2 --project fixture/iOS/Example.xcodeproj --print-target Example`
Expected: output starts with `Target: Example` and includes `Type:`, `Files:`, and `Settings [Release]:`.
