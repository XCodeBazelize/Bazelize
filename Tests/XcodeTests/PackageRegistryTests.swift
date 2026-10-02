@testable import BazelizeKit
import Foundation
import PathKit
import Testing

/// Where a resolved workspace's packages are found. A registry package is not a
/// checkout: SwiftPM unpacks it under `registry/downloads/<scope>/<name>/<version>`,
/// so the directory holding the manifest is a version number and what names the
/// package is the two directories above it.
struct PackageRegistryTests {
    private func scratch(_ build: (Path) throws -> Void) throws -> Path {
        let root = Path(NSTemporaryDirectory()) + "bazelize-registry-\(UUID().uuidString)"
        try (root + "registry/downloads").mkpath()
        try build(root)
        return root
    }

    private func write(manifest directory: Path) throws {
        try directory.mkpath()
        try (directory + "Package.swift").write("// swift-tools-version: 6.0\n")
    }

    @Test
    func aRegistryPackageIsNamedByItsScopeAndName() throws {
        let scratch = try scratch { root in
            try write(manifest: root + "registry/downloads/apple/swift-argument-parser/1.2.0")
        }
        defer { try? scratch.delete() }

        let roots = try SwiftPM.roots(scratch: scratch, locals: [])

        #expect(roots.count == 1)
        #expect(roots.first?.directory == "apple.swift-argument-parser")
        #expect(roots.first?.path.lastComponent == "1.2.0")
        /// A dependency names it by its registry identity, and a product of it
        /// by the package's own name: both have to resolve.
        #expect(roots.first?.identities == ["apple.swift-argument-parser", "swift-argument-parser"])
    }

    @Test
    func aVersionLeftBehindWithoutAManifestIsNotThePackage() throws {
        let scratch = try scratch { root in
            try (root + "registry/downloads/apple/swift-argument-parser/1.1.0").mkpath()
            try write(manifest: root + "registry/downloads/apple/swift-argument-parser/1.2.0")
        }
        defer { try? scratch.delete() }

        let roots = try SwiftPM.roots(scratch: scratch, locals: [])

        #expect(roots.count == 1)
        #expect(roots.first?.path.lastComponent == "1.2.0")
    }

    @Test
    func checkoutsAndRegistryDownloadsAreBothPackages() throws {
        let scratch = try scratch { root in
            try write(manifest: root + "checkouts/Yams")
            try write(manifest: root + "registry/downloads/apple/swift-argument-parser/1.2.0")
        }
        defer { try? scratch.delete() }

        let roots = try SwiftPM.roots(scratch: scratch, locals: [])

        #expect(roots.map(\.directory) == ["Yams", "apple.swift-argument-parser"])
    }

    /// A registry dependency is dumped in a shape of its own — no URL, no path,
    /// only the identity the registry files it under.
    @Test
    func aRegistryDependencyIsReadByItsIdentity() throws {
        let json = """
        {"name": "Package", "platforms": [], "products": [], "targets": [], "dependencies": [
          {"registry": [{
            "identity": "apple.swift-argument-parser",
            "requirement": {"range": [{"lowerBound": "1.2.0", "upperBound": "2.0.0"}]},
            "traits": [{"name": "default"}]
          }]}
        ]}
        """

        let manifest = try JSONDecoder().decode(SwiftPM.Manifest.self, from: Data(json.utf8))

        #expect(manifest.dependencies.map(\.identity) == ["apple.swift-argument-parser"])
        #expect(manifest.dependencies.first?.traits == ["default"])
        #expect(manifest.dependencies.first?.path == nil)
    }
}
