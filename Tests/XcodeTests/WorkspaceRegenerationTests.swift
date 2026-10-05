import BazelizeKit
import Foundation
import PathKit
import Testing

/// What a second run replaces and what it keeps.
///
/// The workspace root carries project configuration and resolved state, while
/// `Packages/` is wholly generated. Rebuilding that subtree removes rules for
/// dependencies and targets that left the graph; otherwise a stale `BUILD`
/// remains part of `//...`.
struct WorkspaceRegenerationTests {
    @Test
    func aDependencyThatLeavesTheGraphTakesItsRulesWithIt() async throws {
        let workspace = Path(NSTemporaryDirectory()) + UUID().uuidString
        defer { try? workspace.delete() }
        let package = workspace + "Root"
        let output = workspace + "App"

        try write(library: "A", in: package)
        try write(library: "B", in: package)
        try (package + "Sources/Root").mkpath()
        try (package + "Sources/Root/Root.swift").write("public let root = 1\n")
        try write(manifest: ["A", "B"], in: package)

        try await Kit(package, nil, outputPath: output).run()
        #expect((output + "Packages/A/BUILD").exists)
        #expect((output + "Packages/B/BUILD").exists)
        try (output + "Packages/A/Generated/Stale").mkpath()
        try (output + "Packages/A/Generated/Stale/output.swift").write("stale\n")

        try write(manifest: ["A"], in: package)
        try await Kit(package, nil, outputPath: output).run()

        #expect((output + "Packages/A/BUILD").exists)
        #expect(!(output + "Packages/B").exists)
        #expect(!(output + "Packages/A/Generated/Stale").exists)
        /// The package handed in keeps its own rules, and the root `BUILD` of
        /// `Packages/` — the flags and conditions every package selects on — is
        /// not a package directory and stays.
        #expect((output + "Packages/Root/BUILD").exists)
        #expect((output + "Packages/BUILD").exists)
    }

    @Test
    func projectBazelrcSurvivesAndGeneratedImportsRemainSingular() async throws {
        let workspace = Path(NSTemporaryDirectory()) + UUID().uuidString
        defer { try? workspace.delete() }
        let package = workspace + "Root"
        let output = workspace + "App"

        try (package + "Sources/Root").mkpath()
        try (package + "Sources/Root/Root.swift").write("public let root = 1\n")
        try write(manifest: [], in: package)
        try output.mkpath()
        try (output + ".bazelrc").write("build --color=no\n")

        try await Kit(package, nil, outputPath: output).run()
        try await Kit(package, nil, outputPath: output).run()

        let contents: String = try (output + ".bazelrc").read()
        #expect(contents.contains("build --color=no"))
        for line in [
            "import %workspace%/config.bazelrc",
            "import %workspace%/traits.bazelrc",
            "import %workspace%/languages.bazelrc",
        ] {
            #expect(contents.components(separatedBy: line).count == 2)
        }
    }

    private func write(library name: String, in package: Path) throws {
        let root = package + name
        try (root + "Sources/\(name)").mkpath()
        try (root + "Sources/\(name)/\(name).swift").write("public let value = 1\n")
        try (root + "Package.swift").write("""
        // swift-tools-version: 6.0
        import PackageDescription

        let package = Package(
            name: "\(name)",
            products: [.library(name: "\(name)", targets: ["\(name)"])],
            targets: [.target(name: "\(name)")])

        """)
    }

    private func write(manifest dependencies: [String], in package: Path) throws {
        let paths = dependencies.map { ".package(path: \"\($0)\")" }.joined(separator: ", ")
        let products = dependencies
            .map { ".product(name: \"\($0)\", package: \"\($0)\")" }
            .joined(separator: ", ")

        try (package + "Package.swift").write("""
        // swift-tools-version: 6.0
        import PackageDescription

        let package = Package(
            name: "Root",
            products: [.library(name: "Root", targets: ["Root"])],
            dependencies: [\(paths)],
            targets: [.target(name: "Root", dependencies: [\(products)])])

        """)
    }
}
