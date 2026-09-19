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

    @Test
    func synchronizedExtensionTargetIncludesExpectedSourceFiles() throws {
        let current = Path(#filePath)
            .parent()
            .parent()
            .parent()
        let projectPath = current + "app/IceCubesApp/IceCubesApp.xcodeproj"

        let project = try Xcode.Project.load(path: projectPath, preferConfig: nil)
        let target = try #require(project.targets.first { $0.name == "IceCubesShareExtension" })

        #expect(target.files.sources.contains { $0.path == "IceCubesShareExtension/ShareViewController.swift" })
        #expect(!target.files.sources.isEmpty)
    }

    @Test
    func resolvesXCConfigSettingsForIINACommandLineTarget() throws {
        let current = Path(#filePath)
            .parent()
            .parent()
            .parent()
        let projectPath = current + "app/iina/IINA.xcodeproj"

        let project = try Xcode.Project.load(path: projectPath, preferConfig: "Release")
        let target = try #require(project.targets.first { $0.name == "iina-cli" })

        #expect(target.prefer(\.platform.sdk) == .macOS)
        #expect(target.prefer(\.platform.macOS) == "10.15")
    }

    @Test
    func classifiesIINAFrameworkDependencies() throws {
        let current = Path(#filePath)
            .parent()
            .parent()
            .parent()
        let projectPath = current + "app/iina/IINA.xcodeproj"

        let project = try Xcode.Project.load(path: projectPath, preferConfig: "Release")
        let target = try #require(project.targets.first { $0.name == "iina" })

        #expect(target.dependencies.sdkFrameworks.contains("CoreDisplay"))
        #expect(target.dependencies.sdkFrameworks.contains("PIP"))
        #expect(!target.dependencies.frameworks.contains("CoreDisplay.framework"))
        #expect(!target.dependencies.frameworks.contains("PIP.framework"))
        /// A dylib the project carries is imported by path, never linked by name
        /// out of the SDK.
        #expect(!target.dependencies.sdkDylibs.contains("libX11.6"))
        #expect((current + "app/iina/deps/lib/libX11.6.dylib").exists
            == target.dependencies.frameworks.contains("//Prebuilt:libX11.6"))
        #expect(target.files.copyFiles.contains { $0.path == "deps/lib/libX11.6.dylib" })
        #expect(target.files.copyFiles.contains { $0.path == "deps/lib/libXau.6.dylib" })
        #expect(target.files.copyFiles.contains { $0.path == "deps/lib/libXdmcp.6.dylib" })
    }
}
