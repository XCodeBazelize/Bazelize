import BazelizeKit
import Foundation
import PathKit
import Testing

/// A dependency named by registry identity.
///
/// No registry is contacted: SwiftPM unpacks a registry download under
/// `.build/registry/downloads/<scope>/<name>/<version>`, and that is the only
/// thing generation reads. The fixture carries what a registry would have
/// served, and this test puts it where SwiftPM would have put it.
///
/// What is therefore *not* covered here is resolution itself — fetching,
/// checksum verification, version selection — which is SwiftPM's, needs a real
/// registry, and cannot run in this suite.
struct RegistryPackageTests {
    @Test
    func aDependencyNamedByRegistryIdentityIsGenerated() async throws {
        let fixture = root + "spm/RegistryPackage"
        let output = Path(NSTemporaryDirectory()) + UUID().uuidString
        defer { try? output.delete() }

        let downloads = output + ".build/registry/downloads"
        try downloads.mkpath()
        for scope in try (fixture + "Registry").children() {
            try scope.copy(downloads + scope.lastComponent)
        }

        let kit = try await Kit(fixture, nil, outputPath: output)
        try await kit.run()

        /// The package is generated under the identity the dependency names,
        /// and the target that depends on it links that label.
        let dependency = output + "Packages/bazelize.registry-dependency/BUILD"
        #expect(dependency.exists)
        let dependencyRules = try String(contentsOfFile: dependency.string, encoding: .utf8)
        #expect(dependencyRules.contains("name = \"RegistryDependency\""))

        let consumer = try String(
            contentsOfFile: (output + "Packages/RegistryPackage/BUILD").string,
            encoding: .utf8)
        #expect(consumer.contains("//Packages/bazelize.registry-dependency:RegistryDependency"))

        /// This machine has no registry configured for the scope, so resolution
        /// fails and generation carries on with what is already unpacked —
        /// saying so rather than writing a workspace that silently lost a
        /// dependency.
        #expect(kit.packageTips.contains { $0.contains("swift package resolve failed") })
    }

    private var root: Path {
        Path(#filePath).parent().parent().parent()
    }
}
