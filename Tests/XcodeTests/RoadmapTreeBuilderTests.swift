import BazelizeKit
import Foundation
import PathKit
import Testing
@testable import Xcode

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
        /// A target depends on the package product, never on the repository that
        /// happens to implement it.
        #expect(exampleBuild.contains("//Packages/AnyCodable:AnyCodable"))
        #expect(exampleBuild.contains("//Packages/Local1:LocalLib1"))
        #expect(exampleBuild.contains("//Packages/Local1:LocalLib2"))
        #expect(!exampleBuild.contains("@swiftpkg_"))
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
        /// The packages are targets of this workspace, so nothing declares a
        /// generator for them.
        #expect(!module.contains("rules_swift_package_manager"))
        #expect(!module.contains("use_repo("))

        /// A product of a local package is the rules of its targets.
        let localBuild = try String(contentsOfFile: (output + "Packages/Local1/BUILD").string)
        #expect(localBuild.contains("swift_library("))
        #expect(localBuild.contains("name = \"LocalTarget1\""))
        #expect(localBuild.contains("module_name = \"LocalTarget1\""))
        /// A product of several targets is a group over them.
        #expect(localBuild.contains("swift_library_group("))
        #expect(localBuild.contains("name = \"LocalLib1\""))
        #expect(localBuild.contains("\":LocalTarget1\""))
        #expect(localBuild.contains("tags = ["))
        #expect(localBuild.contains("\"manual\""))
        #expect(!localBuild.contains("@swiftpkg_"))

        /// A remote package's sources are linked per target, next to its rules.
        let remoteBuild = try String(contentsOfFile: (output + "Packages/AnyCodable/BUILD").string)
        #expect(remoteBuild.contains("name = \"AnyCodable\""))
        #expect(remoteBuild.contains("Sources/AnyCodable/**/*.swift"))
        #expect(!remoteBuild.contains("@swiftpkg_"))
        #expect((output + "Packages/AnyCodable/Sources/AnyCodable").isSymlink)

        /// SwiftPM's working directory is not part of the Bazel workspace.
        let ignore = try String(contentsOfFile: (output + ".bazelignore").string)
        #expect(ignore.contains(".build"))
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
        /// `PRODUCT_NAME` comes from the target's xcconfig, and it is the module a
        /// target's own sources import: iina's Objective-C includes `IINA-Swift.h`.
        #expect(appBuild.contains("module_name = \"IINA\""))
        #expect(appBuild.contains("app_icons = glob(["))
        #expect(appBuild.contains("Sources/iina/Assets.xcassets/AppIcon.appiconset/**"))
        #expect(appBuild.contains("sdk_frameworks = ["))
        #expect(appBuild.contains("\"CoreDisplay\""))
        #expect(appBuild.contains("\"PIP\""))
        #expect(!appBuild.contains("\"CoreDisplay.framework\""))
        #expect(!appBuild.contains("\"PIP.framework\""))
        /// iina links its own dylibs out of `deps/lib`, which the SDK knows nothing
        /// about: they are imported by path when the checkout has them, never linked
        /// by name.
        #expect(!appBuild.contains("\"libX11.6\""))
        #expect(!appBuild.contains("\"libXau.6\""))
        #expect(!appBuild.contains("\"libXdmcp.6\""))
        #expect(!appBuild.contains("cc_import("))
        /// The two command line tools Xcode copies into `Contents/MacOS`.
        #expect(appBuild.contains("\"//Targets/iina-cli:iina-cli\": \"MacOS\""))
        #expect(appBuild.contains("\"//Targets/iina-plugin:iina-plugin\": \"MacOS\""))
        #expect(appBuild.contains("//Packages/GRMustache.swift:Mustache"))
        #expect(!appBuild.contains("@swiftpkg_"))
        #expect(appBuild.contains("macos_application("))
        #expect(appBuild.contains("minimum_os_version = \"10.15\""))

        let nightlyOutput = Path(NSTemporaryDirectory()) + UUID().uuidString
        defer { try? nightlyOutput.delete() }

        let nightlyKit = try await Kit(projectPath, "Nightly", outputPath: nightlyOutput)
        try await nightlyKit.run(projectPath)

        let nightlyBuild = try String(contentsOfFile: (nightlyOutput + "Targets/iina/BUILD").string)
        #expect(nightlyBuild.contains("Sources/iina/Assets.xcassets/AppIconNightly.appiconset/**"))

        let prebuiltBuild = try String(contentsOfFile: (output + "Prebuilt/BUILD").string)
        /// The dylibs iina downloads into `deps/lib` are imported from there when the
        /// checkout has them, and left out entirely when it does not.
        let hasDylibs = (current + "app/iina/deps/lib/libX11.6.dylib").exists
        #expect(prebuiltBuild.contains("libX11.6") == hasDylibs)
        #expect(prebuiltBuild.contains("libXau.6") == hasDylibs)
        #expect(prebuiltBuild.contains("libXdmcp.6") == hasDylibs)
        #expect(!prebuiltBuild.contains("name = \"PIP\""))
        #expect(!prebuiltBuild.contains("name = \"CoreDisplay\""))

        /// A package whose name carries a dot keeps it: the directory is the name a
        /// human refers to the package by.
        let mustacheBuild = try String(contentsOfFile: (output + "Packages/GRMustache.swift/BUILD").string)
        #expect(mustacheBuild.contains("name = \"Mustache\""))
        #expect(mustacheBuild.contains("name = \"GRMustacheKeyAccess\""))
        #expect(mustacheBuild.contains("objc_library("))
    }
}
