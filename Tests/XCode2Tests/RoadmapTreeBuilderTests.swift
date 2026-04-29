import Foundation
import PathKit
import Testing
@testable import XCode2

struct RoadmapTreeBuilderTests {
    @Test
    func buildCreatesTargetTreeAndSymlinks() throws {
        let current = Path(#filePath)
            .parent()
            .parent()
            .parent()
        let projectPath = current + "fixture/iOS/Example.xcodeproj"
        let project = try XCode.Project.load(path: projectPath, preferConfig: nil)

        let output = Path(NSTemporaryDirectory()) + UUID().uuidString
        defer { try? output.delete() }

        try XCode.RoadmapTreeBuilder(output: output).build(project: project)

        #expect((output + "BUILD").exists)
        #expect((output + "MODULE.bazel").exists)
        #expect((output + "Package.swift").exists)
        #expect((output + "Prebuilt").exists)
        #expect((output + "Prebuilt/BUILD").exists)
        #expect((output + "Prebuilt/SVProgressHUD.xcframework").exists)
        #expect((output + "Example/Sources").exists)
        #expect((output + "Example/Generated").exists)
        #expect((output + "Example/BUILD").exists)
        #expect((output + "Framework1/BUILD").exists)
        #expect((output + "Static2/BUILD").exists)

        let exampleDir = output + "Example/Sources/Example"
        #expect(exampleDir.isDirectory)
        #expect(!exampleDir.isSymlink)

        let exampleApp = output + "Example/Sources/Example/ExampleApp.swift"
        #expect(exampleApp.isSymlink)
        #expect(
            try exampleApp.symlinkDestination().absolute().string ==
                (projectPath.parent() + "Example/ExampleApp.swift").absolute().string
        )

        let previewAsset = output + "Example/Sources/Example/Preview Content/Preview Assets.xcassets/Contents.json"
        #expect(previewAsset.isSymlink)
        #expect(
            try previewAsset.symlinkDestination().absolute().string ==
                (projectPath.parent() + "Example/Preview Content/Preview Assets.xcassets/Contents.json").absolute().string
        )

        let exampleBuild = try String(contentsOfFile: (output + "Example/BUILD").string)
        #expect(exampleBuild.contains("ios_application("))
        #expect(exampleBuild.contains("name = \"Example\""))
        #expect(exampleBuild.contains("swift_library("))
        #expect(exampleBuild.contains("name = \"Example_library\""))
        #expect(exampleBuild.contains("//Framework1:Framework1"))
        #expect(exampleBuild.contains("//Prebuilt:SVProgressHUD"))
        #expect(exampleBuild.contains("@swiftpkg_anycodable//:AnyCodable"))
        #expect(exampleBuild.contains("@swiftpkg_local1//:LocalLib1"))
        #expect(exampleBuild.contains("@swiftpkg_local1//:LocalLib2"))

        let frameworkBuild = try String(contentsOfFile: (output + "Framework1/BUILD").string)
        #expect(frameworkBuild.contains("ios_framework("))
        #expect(frameworkBuild.contains("name = \"Framework1\""))

        let static2Build = try String(contentsOfFile: (output + "Static2/BUILD").string)
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
}
