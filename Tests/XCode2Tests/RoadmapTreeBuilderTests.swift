import BazelizeKit
import Foundation
import PathKit
import Testing
@testable import XCode2

struct RoadmapTreeBuilderTests {
    @Test
    func buildCreatesTargetTreeAndSymlinks() async throws {
        let current = Path(#filePath)
            .parent()
            .parent()
            .parent()
        let projectPath = current + "fixture/iOS/Example.xcodeproj"

        let output = Path(NSTemporaryDirectory()) + UUID().uuidString
        defer { try? output.delete() }

        let kit = try await Kit(projectPath, nil, outputPath: output)
        try await kit.run(projectPath)

        #expect((output + "BUILD").exists)
        #expect((output + "MODULE.bazel").exists)
        #expect((output + "Package.swift").exists)
        #expect((output + "Prebuilt").exists)
        #expect((output + "Prebuilt/BUILD").exists)
        #expect((output + "Prebuilt/SVProgressHUD.xcframework").exists)
        #expect((output + "Targets/Example/Sources").exists)
        #expect((output + "Targets/Example/Generated").exists)
        #expect((output + "Targets/Example/BUILD").exists)
        #expect((output + "Targets/Framework1/BUILD").exists)
        #expect((output + "Targets/Static2/BUILD").exists)

        let exampleDir = output + "Targets/Example/Sources/Example"
        #expect(exampleDir.isDirectory)
        #expect(!exampleDir.isSymlink)
        #expect(!(exampleDir + "BUILD").exists)

        let exampleApp = output + "Targets/Example/Sources/Example/ExampleApp.swift"
        #expect(exampleApp.isSymlink)
        #expect(
            try exampleApp.symlinkDestination().absolute().string ==
                (projectPath.parent() + "Example/ExampleApp.swift").absolute().string)

        let previewAsset = output + "Targets/Example/Sources/Example/Preview Content/Preview Assets.xcassets/Contents.json"
        #expect(previewAsset.isSymlink)
        #expect(
            try previewAsset.symlinkDestination().absolute().string ==
                (projectPath.parent() + "Example/Preview Content/Preview Assets.xcassets/Contents.json").absolute().string)

        let exampleBuild = try String(contentsOfFile: (output + "Targets/Example/BUILD").string)
        #expect(exampleBuild.contains("ios_application("))
        #expect(exampleBuild.contains("name = \"Example\""))
        #expect(exampleBuild.contains("swift_library("))
        #expect(exampleBuild.contains("name = \"Example_swift\""))
        #expect(exampleBuild.contains("alias("))
        #expect(exampleBuild.contains("name = \"Example_library\""))
        #expect(exampleBuild.contains("//Targets/Framework1:Framework1_library"))
        #expect(exampleBuild.contains("//Prebuilt:SVProgressHUD"))
        #expect(exampleBuild.contains("@swiftpkg_anycodable//:AnyCodable"))
        #expect(exampleBuild.contains("@swiftpkg_local1//:LocalLib1"))
        #expect(exampleBuild.contains("@swiftpkg_local1//:LocalLib2"))
        #expect(exampleBuild.contains("plist_fragment("))

        let frameworkBuild = try String(contentsOfFile: (output + "Targets/Framework1/BUILD").string)
        #expect(frameworkBuild.contains("ios_framework("))
        #expect(frameworkBuild.contains("name = \"Framework1\""))
        #expect(frameworkBuild.contains("plist_fragment("))
        #expect(frameworkBuild.contains("name = \"plist_default\""))
        #expect(frameworkBuild.contains("infoplists = ["))
        #expect(frameworkBuild.contains("\":plist_default\""))

        let static2Build = try String(contentsOfFile: (output + "Targets/Static2/BUILD").string)
        #expect(static2Build.contains("objc_library("))
        #expect(static2Build.contains("name = \"Static2_objc\""))

        let prebuiltBuild = try String(contentsOfFile: (output + "Prebuilt/BUILD").string)
        #expect(prebuiltBuild.contains("apple_dynamic_xcframework_import("))
        #expect(prebuiltBuild.contains("name = \"SVProgressHUD\""))

        let module = try String(contentsOfFile: (output + "MODULE.bazel").string)
        #expect(module.contains("rules_apple"))
        #expect(module.contains("rules_swift"))
        #expect(module.contains("rules_swift_package_manager"))
        #expect(module.contains("swift_deps = use_extension"))
        #expect(module.contains("swiftpkg_local1"))
    }

    @Test
    func applicationEmbedsExtensionsInsteadOfLinkingThemAsRegularDeps() async throws {
        let current = Path(#filePath)
            .parent()
            .parent()
            .parent()
        let projectPath = current + "app/IceCubesApp/IceCubesApp.xcodeproj"

        let output = Path(NSTemporaryDirectory()) + UUID().uuidString
        defer { try? output.delete() }

        let kit = try await Kit(projectPath, nil, outputPath: output)
        try await kit.run(projectPath)

        let appBuild = try String(contentsOfFile: (output + "Targets/IceCubesApp/BUILD").string)
        #expect(appBuild.contains("ios_application("))
        #expect(appBuild.contains("extensions = ["))
        #expect(appBuild.contains("//Targets/IceCubesActionExtension:IceCubesActionExtension"))
        #expect(appBuild.contains("//Targets/IceCubesAppWidgetsExtensionExtension:IceCubesAppWidgetsExtensionExtension"))
        #expect(appBuild.contains("//Targets/IceCubesNotifications:IceCubesNotifications"))
        #expect(appBuild.contains("//Targets/IceCubesShareExtension:IceCubesShareExtension"))
        #expect(!appBuild.contains("//Targets/IceCubesActionExtension:IceCubesActionExtension_library"))
        #expect(!appBuild.contains("//Targets/IceCubesAppWidgetsExtensionExtension:IceCubesAppWidgetsExtensionExtension_library"))
        #expect(!appBuild.contains("//Targets/IceCubesNotifications:IceCubesNotifications_library"))
        #expect(!appBuild.contains("//Targets/IceCubesShareExtension:IceCubesShareExtension_library"))
    }

    @Test
    func iinaTargetsGenerateSanitizedModuleNamesAndMacAppRules() async throws {
        let current = Path(#filePath)
            .parent()
            .parent()
            .parent()
        let projectPath = current + "app/iina/IINA.xcodeproj"

        let output = Path(NSTemporaryDirectory()) + UUID().uuidString
        defer { try? output.delete() }

        let kit = try await Kit(projectPath, "Release", outputPath: output)
        try await kit.run(projectPath)

        let cliBuild = try String(contentsOfFile: (output + "Targets/iina-cli/BUILD").string)
        #expect(cliBuild.contains("module_name = \"iina_cli\""))
        #expect(cliBuild.contains("minimum_os_version = \"10.15\""))

        let pluginBuild = try String(contentsOfFile: (output + "Targets/iina-plugin/BUILD").string)
        #expect(pluginBuild.contains("module_name = \"iina_plugin\""))

        let appBuild = try String(contentsOfFile: (output + "Targets/iina/BUILD").string)
        #expect(appBuild.contains("mixed_language_library("))
        #expect(appBuild.contains("name = \"iina_mixed\""))
        #expect(appBuild.contains("module_name = \"iina\""))
        #expect(appBuild.contains("app_icons = glob(["))
        #expect(appBuild.contains("Sources/iina/Assets.xcassets/AppIcon.appiconset/**"))
        #expect(appBuild.contains("sdk_frameworks = ["))
        #expect(appBuild.contains("\"CoreDisplay\""))
        #expect(appBuild.contains("\"PIP\""))
        #expect(!appBuild.contains("\"CoreDisplay.framework\""))
        #expect(!appBuild.contains("\"PIP.framework\""))
        #expect(appBuild.contains("sdk_dylibs = ["))
        #expect(appBuild.contains("\"libX11.6\""))
        #expect(appBuild.contains("\"libXau.6\""))
        #expect(appBuild.contains("\"libXdmcp.6\""))
        #expect(!appBuild.contains("cc_import("))
        #expect(!appBuild.contains("additional_contents = {"))
        #expect(appBuild.contains("@swiftpkg_grmustache.swift//:Mustache"))
        #expect(appBuild.contains("macos_application("))
        #expect(appBuild.contains("minimum_os_version = \"10.15\""))

        let nightlyOutput = Path(NSTemporaryDirectory()) + UUID().uuidString
        defer { try? nightlyOutput.delete() }

        let nightlyKit = try await Kit(projectPath, "Nightly", outputPath: nightlyOutput)
        try await nightlyKit.run(projectPath)

        let nightlyBuild = try String(contentsOfFile: (nightlyOutput + "Targets/iina/BUILD").string)
        #expect(nightlyBuild.contains("Sources/iina/Assets.xcassets/AppIconNightly.appiconset/**"))

        let prebuiltBuild = try String(contentsOfFile: (output + "Prebuilt/BUILD").string)
        #expect(!prebuiltBuild.contains("libX11.6"))
        #expect(!prebuiltBuild.contains("libXau.6"))
        #expect(!prebuiltBuild.contains("libXdmcp.6"))
        #expect(!prebuiltBuild.contains("name = \"PIP\""))
        #expect(!prebuiltBuild.contains("name = \"CoreDisplay\""))

        let module = try String(contentsOfFile: (output + "MODULE.bazel").string)
        #expect(module.contains("swiftpkg_grmustache.swift"))
        #expect(!module.contains("swiftpkg_swiftpkg_"))
    }
}
