import PathKit
import Testing
@testable import Xcode

struct ProjectLoaderTests {
    @Test
    func mergeLocalPackagesKeepsExplicitEntriesFirstAndDeduplicatesByPath() {
        let explicit: [Xcode.LocalPackage] = [
            .init(name: "Local1", relativePath: "Local1"),
            .init(name: "Local2", relativePath: "Local2"),
        ]
        let discovered: [Xcode.LocalPackage] = [
            .init(name: "Local1 (Scanned)", relativePath: "Local1"),
            .init(name: "Local3", relativePath: "Local3"),
        ]

        let merged = ProjectLoader.mergeLocalPackages(
            explicit: explicit,
            discovered: discovered)

        #expect(merged.map(\.relativePath) == ["Local1", "Local2", "Local3"])
        #expect(merged.first?.name == "Local1")
        #expect(merged.last?.name == "Local3")
    }

    @Test(.corpus("IceCubesApp/IceCubesApp.xcodeproj"))
    func synchronizedExtensionTargetIncludesExpectedSourceFiles() throws {
        let current = Path(#filePath)
            .parent()
            .parent()
            .parent()
        let projectPath = current + "app/IceCubesApp/IceCubesApp.xcodeproj"

        let project = try Xcode.Project.load(path: projectPath, preferConfig: nil)
        let extensionSources = project.withTarget(named: "IceCubesShareExtension") { $0.files.sources }
        let sources = try #require(extensionSources)

        #expect(sources.contains { $0.path == "IceCubesShareExtension/ShareViewController.swift" })
        #expect(!sources.isEmpty)
    }

    @Test(.corpus("iina/IINA.xcodeproj"))
    func resolvesXCConfigSettingsForIINACommandLineTarget() throws {
        let current = Path(#filePath)
            .parent()
            .parent()
            .parent()
        let projectPath = current + "app/iina/IINA.xcodeproj"

        let project = try Xcode.Project.load(path: projectPath, preferConfig: "Release")
        let cliIndex = project.targetIndex(named: "iina-cli")
        let cli = try #require(cliIndex)

        #expect(project.targets[cli].prefer(\.platform.sdk) == .macOS)
        #expect(project.targets[cli].prefer(\.platform.macOS) == "10.15")
    }

    @Test(.corpus("iina/IINA.xcodeproj"))
    func classifiesIINAFrameworkDependencies() throws {
        let current = Path(#filePath)
            .parent()
            .parent()
            .parent()
        let projectPath = current + "app/iina/IINA.xcodeproj"

        let project = try Xcode.Project.load(path: projectPath, preferConfig: "Release")
        let iinaDependencies = project.withTarget(named: "iina") { $0.dependencies }
        let iinaCopyFiles = project.withTarget(named: "iina") { $0.files.copyFiles }
        let dependencies = try #require(iinaDependencies)
        let copyFiles = try #require(iinaCopyFiles)

        #expect(dependencies.sdkFrameworks.contains("CoreDisplay"))
        #expect(dependencies.sdkFrameworks.contains("PIP"))
        #expect(!dependencies.frameworks.contains("CoreDisplay.framework"))
        #expect(!dependencies.frameworks.contains("PIP.framework"))
        /// A dylib the project carries is imported by path, never linked by name
        /// out of the SDK.
        #expect(!dependencies.sdkDylibs.contains("libX11.6"))
        #expect((current + "app/iina/deps/lib/libX11.6.dylib").exists
            == dependencies.frameworks.contains("//Prebuilt:libX11.6"))
        #expect(copyFiles.contains { $0.path == "deps/lib/libX11.6.dylib" })
        #expect(copyFiles.contains { $0.path == "deps/lib/libXau.6.dylib" })
        #expect(copyFiles.contains { $0.path == "deps/lib/libXdmcp.6.dylib" })
    }
}
