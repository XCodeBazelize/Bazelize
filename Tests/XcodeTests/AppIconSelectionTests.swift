import Foundation
import PathKit
import Testing
import Xcode
@testable import BazelizeKit

struct AppIconSelectionTests {
    @Test
    func composerPrimaryKeepsItsLegacyFallbackAndExplicitAlternates() async throws {
        let root = try fixture(settings: [
            "ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES": "\"Dark Mode\"",
            "ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS": "NO",
        ])
        defer { try? root.delete() }
        let selection = try await selection(root)
        #expect(selection.primary == "AppIcon")
        #expect(Set(selection.patterns) == [
            "Sources/AppIcon.icon/**",
            "Sources/Assets.xcassets/AppIcon.appiconset/**",
            "Sources/Assets.xcassets/Dark Mode.appiconset/**",
        ])
    }

    @Test
    func includeAllDiscoversSynchronizedComposerAndLegacyAlternates() async throws {
        let root = try fixture(settings: ["ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS": "YES"])
        defer { try? root.delete() }
        let selection = try await selection(root)
        #expect(Set(selection.patterns) == [
            "Sources/AppIcon.icon/**",
            "Sources/Assets.xcassets/AppIcon.appiconset/**",
            "Sources/Assets.xcassets/Dark Mode.appiconset/**",
            "Sources/Assets.xcassets/Other.appiconset/**",
            "Sources/AlternateIcons/Glass.icon/**",
        ])
    }

    @Test(arguments: [false, true])
    func aLegacyPrimaryDoesNotSelectUnrequestedAlternateIcons(includeSetting: Bool) async throws {
        let root = try fixture(settings: includeSetting ? ["ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS": "NO"] : [:])
        defer { try? root.delete() }
        try (root + "AppIcon.icon").delete()
        let selection = try await selection(root)
        #expect(selection.patterns == ["Sources/Assets.xcassets/AppIcon.appiconset/**"])
        #expect(selection.primaryAppIcon == nil)
    }

    @Test
    func aMissingPrimaryDoesNotGenerateAnEmptyIconGlob() async throws {
        let root = try fixture(settings: ["ASSETCATALOG_COMPILER_APPICON_NAME": "Missing"])
        defer { try? root.delete() }
        let project = try await Xcode.Project.load(path: root + "Project.xcodeproj", preferConfig: "Release")
        let index = try #require(project.targets.indices.first)
        let selection = project.targets[index].appIconSelection(project: project)
        #expect(selection == nil)
    }

    private func selection(_ root: Path) async throws -> AppIconSelection {
        let project = try await Xcode.Project.load(path: root + "Project.xcodeproj", preferConfig: "Release")
        let index = try #require(project.targets.indices.first)
        let selection = project.targets[index].appIconSelection(project: project)
        return try #require(selection)
    }

    private func fixture(settings: [String: String]) throws -> Path {
        let root = Path(NSTemporaryDirectory()) + UUID().uuidString
        try (root + "Project.xcodeproj").mkpath()
        for path in [
            "AppIcon.icon/icon.json", "AlternateIcons/Glass.icon/icon.json",
            "Assets.xcassets/AppIcon.appiconset/Contents.json",
            "Assets.xcassets/Dark Mode.appiconset/Contents.json",
            "Assets.xcassets/Other.appiconset/Contents.json",
        ] {
            let file = root + path
            try file.parent().mkpath()
            try file.write("{}")
        }
        var buildSettings = [
            "SDKROOT": "iphoneos",
            "IPHONEOS_DEPLOYMENT_TARGET": "18.5",
            "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
        ]
        buildSettings.merge(settings) { _, value in value }
        let json: [String: Any] = [
            "default-configuration": "Release", "configurations": ["Release"],
            "localizations": ["development": "en", "supported": ["en"]],
            "packages": [],
            "files": [
                ["path": "Assets.xcassets", "type": "folder.assetcatalog", "target-membership": ["Probe/resources"]],
                ["path": "AppIcon.icon", "type": "folder.iconcomposer.icon", "target-membership": ["Probe/resources"]],
                ["kind": "folder", "path": "AlternateIcons", "target-membership": ["Probe"]],
                [
                    "kind": "group",
                    "name": "Products",
                    "children": [[
                        "path": "<PRODUCTS>/Probe.app",
                        "type": "wrapper.application",
                        "id": "000000000000000000000120",
                    ]],
                ],
            ],
            "targets": [[
                "name": "Probe",
                "id": "000000000000000100000000",
                "product": "Products/Probe.app",
                "product-type": "application",
                "build-phases": ["resources"],
            ]],
            "build-settings": buildSettings,
        ]
        try (root + "Project.xcodeproj/project.xcproj").write(JSONSerialization.data(
            withJSONObject: json,
            options: [.sortedKeys]))
        return root
    }
}
