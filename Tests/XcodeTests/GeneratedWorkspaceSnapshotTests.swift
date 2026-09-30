import BazelizeKit
import Foundation
import PathKit
import Testing
@testable import Xcode

/// What a run writes, kept verbatim.
///
/// The other tests say what a generated file has to contain; these say what it
/// is. A rule that changes shape — an attribute that appears, a `select` that
/// collapses, a label that moves — shows up here as a diff in review rather
/// than as nothing at all, which is the only way a change to the output is
/// looked at before it ships.
///
/// Recording is deliberate: run the suite with `BAZELIZE_RECORD_SNAPSHOTS=1`,
/// read the diff, commit it with the change that caused it.
struct GeneratedWorkspaceSnapshotTests {
    @Test
    func xcodeProjectWorkspace() async throws {
        try await verify(
            input: "fixture/iOS/Example.xcodeproj",
            snapshot: "iOS",
            files: [
                "BUILD",
                "MODULE.bazel",
                "config.bazelrc",
                "Prebuilt/BUILD",
                "Targets/Example/BUILD",
                "Targets/MacBundle/BUILD",
                "Targets/Framework1/BUILD",
                "Targets/Static2/BUILD",
                "Targets/StaticFramework1/BUILD",
                "Packages/Local1/BUILD"
            ])
    }

    @Test
    func swiftPackageResources() async throws {
        try await verify(
            input: "spm/TargetResource",
            snapshot: "TargetResource",
            files: [
                "MODULE.bazel",
                "Packages/TargetResource/BUILD"
            ])
    }

    // MARK: Private

    private var root: Path {
        Path(#filePath).parent().parent().parent()
    }

    /// Generates the input into a directory of its own and compares what landed
    /// with what was recorded.
    private func verify(input: String, snapshot name: String, files: [String]) async throws {
        let output = Path(NSTemporaryDirectory()) + UUID().uuidString
        defer { try? output.delete() }

        let kit = try await Kit(root + input, nil, outputPath: output)
        try await kit.run()

        let recorded = root + "Tests/Snapshots" + name
        for file in files {
            let generated = try String(contentsOfFile: (output + file).string, encoding: .utf8)
            let path = recorded + file

            guard ProcessInfo.processInfo.environment["BAZELIZE_RECORD_SNAPSHOTS"] == nil else {
                try path.parent().mkpath()
                try path.write(generated)
                continue
            }

            guard path.exists else {
                Issue.record("""
                \(name)/\(file) has no snapshot. \
                Record it with BAZELIZE_RECORD_SNAPSHOTS=1 swift test.
                """)
                continue
            }

            let expected = try String(contentsOfFile: path.string, encoding: .utf8)
            guard generated != expected else { continue }

            Issue.record("""
            \(name)/\(file) is not what was recorded:
            \(Self.diff(expected: expected, generated: generated))
            Record the new output with BAZELIZE_RECORD_SNAPSHOTS=1 swift test.
            """)
        }
    }

    /// The lines that differ, with the line numbers to find them by: a whole
    /// generated file in a failure message is unreadable, and the first
    /// difference is usually the only one that matters.
    private static func diff(expected: String, generated: String) -> String {
        let left = expected.components(separatedBy: "\n")
        let right = generated.components(separatedBy: "\n")

        var lines: [String] = []
        for index in 0 ..< max(left.count, right.count) {
            let before = index < left.count ? left[index] : nil
            let after = index < right.count ? right[index] : nil
            guard before != after else { continue }

            if let before { lines.append("\(index + 1)- \(before)") }
            if let after { lines.append("\(index + 1)+ \(after)") }
            guard lines.count < 40 else {
                lines.append("…")
                break
            }
        }
        return lines.joined(separator: "\n")
    }
}
