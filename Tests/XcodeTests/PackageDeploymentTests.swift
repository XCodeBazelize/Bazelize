import Foundation
import PathKit
import Testing
@testable import BazelizeKit

/// What version a package's targets end up compiled at, and when that is a
/// problem worth telling the user about.
struct PackageDeploymentTests {
    private func manifest(platforms: [(String, String)], products: [String] = []) -> SwiftPM.Manifest {
        let entries = platforms.map { platform, version in
            """
            {"platformName": "\(platform)", "version": "\(version)"}
            """
        }.joined(separator: ",")
        let productEntries = products.map { name in
            """
            {"name": "\(name)", "targets": [], "type": {"library": ["automatic"]}}
            """
        }.joined(separator: ",")

        let json = """
        {"name": "Package", "platforms": [\(entries)], "products": [\(productEntries)], "targets": [], "dependencies": []}
        """

        // swiftlint:disable:next force_try
        return try! JSONDecoder().decode(SwiftPM.Manifest.self, from: Data(json.utf8))
    }

    private func package(
        _ directory: String = "Example",
        platforms: [(String, String)] = [],
        products: [String] = [])
        -> SwiftPM.Package
    {
        .init(
            directory: directory,
            root: Path("/tmp/\(directory)"),
            manifest: manifest(platforms: platforms, products: products),
            isLocal: false,
            isRoot: false)
    }

    private func workspace(_ packages: [SwiftPM.Package]) -> SwiftPM.Workspace {
        .init(packages: packages, artifacts: "/tmp/artifacts", directoryByIdentity: [:], traits: [:], notes: [])
    }

    @Test
    func aGraphIsBuiltAtTheNewestVersionAnyPackageDeclares() {
        let floors = workspace([
            package("A", platforms: [("ios", "15.0"), ("macos", "13.0"), ("linux", "99")]),
            package("B", platforms: [("ios", "16.4"), ("macos", "12.0"), ("tvos", "")]),
        ]).deploymentFloors

        /// Linux is no Apple platform, and an empty version declares nothing.
        #expect(floors == [.iOS: "16.4", .macOS: "13.0"])
    }

    @Test
    func aProjectIsBuiltAtTheOldestVersionItsTargetsDeclare() {
        let floors = SwiftPM.Deployment.oldest([
            (.iOS, "16.0"),
            (.iOS, "15.4"),
            (.macOS, nil),
            (.macOS, "14.0"),
            (.tvOS, ""),
        ])

        #expect(floors == [.iOS: "15.4", .macOS: "14.0"])
    }

    @Test
    func aProductTwoPackagesDeclareNamesNeither() {
        let directories = workspace([
            package("A", products: ["Shared", "OnlyA"]),
            package("B", products: ["Shared", "OnlyB"]),
        ]).packageDirectoryByProduct

        #expect(directories == ["OnlyA": "A", "OnlyB": "B"])
    }

    @Test
    func declaredVersionWins() {
        let deployment = SwiftPM.Deployment(project: [.iOS: "14.0"])

        #expect(deployment.required(package(platforms: [("ios", "16.0")]), platform: .iOS) == "16.0")
    }

    @Test
    func undeclaredPlatformFallsBackToWhatSwiftPMBuilds() {
        let deployment = SwiftPM.Deployment(project: [.iOS: "14.0"])
        let declared = package(platforms: [("macos", "13.0")])

        /// The package says nothing about iOS, so SwiftPM's own floor for the
        /// platform is what it would be built at.
        #expect(deployment.required(declared, platform: .iOS) == SwiftPM.ApplePlatform.iOS.swiftPMFloor)
        #expect(deployment.required(declared, platform: .macOS) == "13.0")
    }

    @Test
    func aPackageAskingForMoreThanTheProjectIsReported() {
        let deployment = SwiftPM.Deployment(project: [.iOS: "14.0", .macOS: "13.0"])
        let unmet = deployment.unmet(package(platforms: [("ios", "16.0"), ("macos", "12.0")]))

        #expect(unmet.count == 1)
        #expect(unmet.first?.platform == .iOS)
        #expect(unmet.first?.required == "16.0")
        #expect(unmet.first?.project == "14.0")
    }

    @Test
    func anUndeclaredPlatformIsNotReported() {
        let deployment = SwiftPM.Deployment(project: [.iOS: "14.0"])

        /// SwiftPM raises the consumer to its own floor too, so a package that
        /// declares nothing is never why a graph is rejected.
        #expect(deployment.unmet(package(platforms: [("macos", "13.0")])).isEmpty)
    }

    @Test
    func aPackageWithinTheProjectsReachIsNotReported() {
        let deployment = SwiftPM.Deployment(project: [.iOS: "18.5"])

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
