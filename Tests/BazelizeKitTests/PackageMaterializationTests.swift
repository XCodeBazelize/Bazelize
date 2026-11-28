import Foundation
import PathKit
import Testing
@testable import BazelizeKit

struct PackageMaterializationTests {
    @Test(arguments: [false, true], ["CustomSQLite", "Fixtures/CustomSQLite"])
    func mirroredSourcesPruneExcludedPaths(nestedOutput: Bool, excluded: String) throws {
        let fixture = Fixture(nestedOutput: nestedOutput, excluded: excluded)
        defer { try? fixture.root.delete() }
        try fixture.sourceRoot.mkpath()
        try fixture.keptDirectory.mkpath()
        try fixture.source.write("public let value = 1\n")
        try fixture.keptSource.write("public let kept = 2\n")
        try fixture.hiddenSource.write("#error(\"excluded source\")\n")
        try fixture.backlink.parent().mkpath()
        try fixture.backlink.symlink(fixture.packageRoot)

        let data = Data("""
        {"name":"Probe","targets":[{
            "name":"Probe","type":"regular","path":"Tests",
            "exclude":["\(excluded)","Hidden.swift"]
        }]}
        """.utf8)
        let manifest = try JSONDecoder().decode(SwiftPM.Manifest.self, from: data)
        let target = try #require(manifest.targets.first)
        let package = SwiftPM.Package(
            directory: "Probe", root: fixture.packageRoot, manifest: manifest, isLocal: true, isRoot: true)
        let workspace = SwiftPM.Workspace(
            packages: [package], artifacts: fixture.artifacts, directoryByIdentity: [:], traits: [:], notes: [])
        let generator = SwiftPM.Generator(
            output: fixture.outputRoot, workspace: workspace, deployment: .init(project: [:]))

        _ = try generator.materialize(target, in: package, at: fixture.packageOutput)

        #expect(try fixture.generatedSource.read() == "public let value = 1\n")
        #expect(try fixture.generatedKeptSource.read() == "public let kept = 2\n")
        #expect(!fixture.generatedExcluded.exists && !fixture.generatedExcluded.isSymlink)
        #expect(!fixture.generatedHiddenSource.exists && !fixture.generatedHiddenSource.isSymlink)
    }

    private struct Fixture {
        let root = Path(NSTemporaryDirectory()) + UUID().uuidString
        let nestedOutput: Bool
        let excluded: String

        var packageRoot: Path { root + "Probe" }
        var sourceRoot: Path { packageRoot + "Tests" }
        var source: Path { sourceRoot + "Probe.swift" }
        var keptDirectory: Path { sourceRoot + "Fixtures" }
        var keptSource: Path { keptDirectory + "Kept.swift" }
        var hiddenSource: Path { sourceRoot + "Hidden.swift" }
        var backlink: Path { sourceRoot + excluded + "GRDB" }
        var outputRoot: Path { (nestedOutput ? packageRoot : root) + "App" }
        var packageOutput: Path { outputRoot + "Packages/Probe" }
        var artifacts: Path { outputRoot + ".build/artifacts" }
        var generatedRoot: Path { packageOutput + "Sources/Probe" }
        var generatedSource: Path { generatedRoot + "Probe.swift" }
        var generatedKeptSource: Path { generatedRoot + "Fixtures/Kept.swift" }
        var generatedHiddenSource: Path { generatedRoot + "Hidden.swift" }
        var generatedExcluded: Path { generatedRoot + excluded }
    }
}
