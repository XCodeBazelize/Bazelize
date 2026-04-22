import Foundation
import PathKit
import XCTest
@testable import XCode2

final class RoadmapTreeBuilderTests: XCTestCase {
    func testBuildCreatesTargetTreeAndSymlinks() throws {
        let projectPath = Path.current + "fixture/iOS2/Example.xcodeproj"
        let project = try XCode.Project.load(path: projectPath, preferConfig: nil)

        let output = Path(NSTemporaryDirectory()) + UUID().uuidString
        defer { try? output.delete() }

        try XCode.RoadmapTreeBuilder(output: output).build(project: project)

        XCTAssertTrue((output + "BUILD").exists)
        XCTAssertTrue((output + "MODULE.bazel").exists)
        XCTAssertTrue((output + "Package.swift").exists)
        XCTAssertTrue((output + "Prebuilt").exists)
        XCTAssertTrue((output + "Prebuilt/BUILD").exists)
        XCTAssertTrue((output + "Prebuilt/SVProgressHUD.xcframework").exists)
        XCTAssertTrue((output + "Example/Sources").exists)
        XCTAssertTrue((output + "Example/Generated").exists)
        XCTAssertTrue((output + "Example/BUILD").exists)
        XCTAssertTrue((output + "Framework1/BUILD").exists)
        XCTAssertTrue((output + "Static2/BUILD").exists)

        let exampleDir = output + "Example/Sources/Example"
        XCTAssertTrue(exampleDir.isDirectory)
        XCTAssertFalse(exampleDir.isSymlink)

        let exampleApp = output + "Example/Sources/Example/ExampleApp.swift"
        XCTAssertTrue(exampleApp.isSymlink)
        XCTAssertEqual(
            try exampleApp.symlinkDestination().absolute().string,
            (projectPath.parent() + "Example/ExampleApp.swift").absolute().string
        )

        let previewAsset = output + "Example/Sources/Example/Preview Content/Preview Assets.xcassets/Contents.json"
        XCTAssertTrue(previewAsset.isSymlink)
        XCTAssertEqual(
            try previewAsset.symlinkDestination().absolute().string,
            (projectPath.parent() + "Example/Preview Content/Preview Assets.xcassets/Contents.json").absolute().string
        )

        let exampleBuild = try String(contentsOfFile: (output + "Example/BUILD").string)
        XCTAssertTrue(exampleBuild.contains("ios_application("))
        XCTAssertTrue(exampleBuild.contains("name = \"Example\""))
        XCTAssertTrue(exampleBuild.contains("swift_library("))
        XCTAssertTrue(exampleBuild.contains("name = \"Example_library\""))
        XCTAssertTrue(exampleBuild.contains("//Framework1:Framework1"))
        XCTAssertTrue(exampleBuild.contains("//Prebuilt:SVProgressHUD"))
        XCTAssertTrue(exampleBuild.contains("@swiftpkg_anycodable//:AnyCodable"))
        XCTAssertTrue(exampleBuild.contains("@swiftpkg_local1//:LocalLib1"))
        XCTAssertTrue(exampleBuild.contains("@swiftpkg_local1//:LocalLib2"))

        let frameworkBuild = try String(contentsOfFile: (output + "Framework1/BUILD").string)
        XCTAssertTrue(frameworkBuild.contains("ios_framework("))
        XCTAssertTrue(frameworkBuild.contains("name = \"Framework1\""))

        let static2Build = try String(contentsOfFile: (output + "Static2/BUILD").string)
        XCTAssertTrue(static2Build.contains("objc_library("))
        XCTAssertTrue(static2Build.contains("name = \"Static2_objc\""))

        let prebuiltBuild = try String(contentsOfFile: (output + "Prebuilt/BUILD").string)
        XCTAssertTrue(prebuiltBuild.contains("apple_dynamic_xcframework_import("))
        XCTAssertTrue(prebuiltBuild.contains("name = \"SVProgressHUD\""))

        let module = try String(contentsOfFile: (output + "MODULE.bazel").string)
        XCTAssertTrue(module.contains("rules_apple"))
        XCTAssertTrue(module.contains("rules_swift"))
        XCTAssertTrue(module.contains("rules_swift_package_manager"))
        XCTAssertTrue(module.contains("swift_deps = use_extension"))
        XCTAssertTrue(module.contains("swiftpkg_local1"))
    }
}
