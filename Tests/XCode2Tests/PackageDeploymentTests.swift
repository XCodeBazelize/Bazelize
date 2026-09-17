@testable import BazelizeKit
import Foundation
import Testing

/// What version a package's targets end up compiled at, and when that is a
/// problem worth telling the user about.
struct PackageDeploymentTests {
    private func manifest(platforms: [(String, String)]) -> SwiftPM.Manifest {
        let entries = platforms.map { platform, version in
            """
            {"platformName": "\(platform)", "version": "\(version)"}
            """
        }.joined(separator: ",")

        let json = """
        {"name": "Package", "platforms": [\(entries)], "products": [], "targets": [], "dependencies": []}
        """

        // swiftlint:disable:next force_try
        return try! JSONDecoder().decode(SwiftPM.Manifest.self, from: Data(json.utf8))
    }

    private func package(platforms: [(String, String)]) -> SwiftPM.Package {
        .init(
            directory: "Example",
            root: "/tmp/Example",
            manifest: manifest(platforms: platforms),
            isLocal: false,
            isRoot: false)
    }

    @Test
    func declaredVersionWins() {
        let deployment = SwiftPM.Deployment(project: ["ios": "14.0"])

        #expect(deployment.required(package(platforms: [("ios", "16.0")]), platform: "ios") == "16.0")
    }

    @Test
    func undeclaredPlatformFallsBackToWhatSwiftPMBuilds() {
        let deployment = SwiftPM.Deployment(project: ["ios": "14.0"])
        let declared = package(platforms: [("macos", "13.0")])

        /// The package says nothing about iOS, so SwiftPM's own floor for the
        /// platform is what it would be built at.
        #expect(deployment.required(declared, platform: "ios") == SwiftPM.Deployment.oldest["ios"])
        #expect(deployment.required(declared, platform: "macos") == "13.0")
    }

    @Test
    func aPackageAskingForMoreThanTheProjectIsReported() {
        let deployment = SwiftPM.Deployment(project: ["ios": "14.0", "macos": "13.0"])
        let unmet = deployment.unmet(package(platforms: [("ios", "16.0"), ("macos", "12.0")]))

        #expect(unmet.count == 1)
        #expect(unmet.first?.platform == "ios")
        #expect(unmet.first?.required == "16.0")
        #expect(unmet.first?.project == "14.0")
    }

    @Test
    func anUndeclaredPlatformIsNotReported() {
        let deployment = SwiftPM.Deployment(project: ["ios": "14.0"])

        /// SwiftPM raises the consumer to its own floor too, so a package that
        /// declares nothing is never why a graph is rejected.
        #expect(deployment.unmet(package(platforms: [("macos", "13.0")])).isEmpty)
    }

    @Test
    func aPackageWithinTheProjectsReachIsNotReported() {
        let deployment = SwiftPM.Deployment(project: ["ios": "18.5"])

        #expect(deployment.unmet(package(platforms: [("ios", "16.0")])).isEmpty)
    }

    @Test
    func versionsCompareByComponent() {
        #expect(SwiftPM.Deployment.isNewer("10.15", than: "10.9"))
        #expect(SwiftPM.Deployment.isNewer("16.0", than: "15.4"))
        #expect(!SwiftPM.Deployment.isNewer("14.0", than: "14"))
        #expect(!SwiftPM.Deployment.isNewer("13.0", than: "14.0"))
    }
}
