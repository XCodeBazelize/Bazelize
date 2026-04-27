import XCTest
@testable import XCode2

final class TargetSummaryFormatterTests: XCTestCase {
    func testFormatTargetSummary() throws {
        let target = XCode.Target(
            name: "Example",
            productName: "Example",
            productType: "com.apple.product-type.application",
            configs: [
                "Debug": .init(
                    name: "Debug",
                    setting: [
                        "SWIFT_VERSION": "5.9",
                    ]
                ),
                "Release": .init(
                    name: "Release",
                    setting: [
                        "INFOPLIST_FILE": "Example/Info.plist",
                        "IPHONEOS_DEPLOYMENT_TARGET": "16.0",
                        "PRODUCT_BUNDLE_IDENTIFIER": "com.example.Example",
                        "SWIFT_VERSION": "5.9",
                        "TARGETED_DEVICE_FAMILY": "1 2",
                    ]
                ),
            ],
            metadata: .init(
                bundleID: "com.example.Example",
                moduleName: "Example",
                infoPlist: "Example/Info.plist",
                deploymentTargets: ["iOS": "16.0"],
                codeSign: .init(
                    developmentTeam: nil,
                    codeSignStyle: "Automatic",
                    codeSignIdentity: nil
                )
            ),
            buildPhases: [],
            files: .init(
                sources: [
                    .init(
                        name: "ExampleApp.swift",
                        path: "Example/ExampleApp.swift",
                        fullPath: "/tmp/Example/ExampleApp.swift",
                        label: nil,
                        fileType: "sourcecode.swift",
                        sourceTree: "<group>",
                        buildPhase: "sources",
                        compilerFlags: nil,
                        attributes: []
                    ),
                ],
                headers: [],
                resources: [
                    .init(
                        name: "Assets.xcassets",
                        path: "Example/Assets.xcassets",
                        fullPath: "/tmp/Example/Assets.xcassets",
                        label: nil,
                        fileType: "folder.assetcatalog",
                        sourceTree: "<group>",
                        buildPhase: "resources",
                        compilerFlags: nil,
                        attributes: []
                    ),
                ],
                frameworks: [],
                copyFiles: [],
                others: []
            ),
            dependencies: .init(
                targets: ["Framework1"],
                packageProducts: [],
                frameworks: [],
                sdkFrameworks: ["SwiftUI", "UIKit"]
            )
        )

        let project = XCode.Project(
            name: "Example",
            workspacePath: "/tmp",
            projectPath: "/tmp/Example.xcodeproj",
            preferConfig: "Release",
            configs: [:],
            packages: .init(remote: [], local: []),
            targets: [target]
        )

        let summary = XCode.TargetSummaryFormatter.format(project: project, target: target)

        XCTAssertTrue(summary.contains("Target: Example"))
        XCTAssertTrue(summary.contains("Type: com.apple.product-type.application"))
        XCTAssertTrue(summary.contains("Bundle ID: com.example.Example"))
        XCTAssertTrue(summary.contains("Sources:"))
        XCTAssertTrue(summary.contains("- Example/ExampleApp.swift"))
        XCTAssertTrue(summary.contains("Resources:"))
        XCTAssertTrue(summary.contains("Dependencies:"))
        XCTAssertTrue(summary.contains("SDK Frameworks:"))
        XCTAssertTrue(summary.contains("Settings [Release]:"))
        XCTAssertTrue(summary.contains("PRODUCT_BUNDLE_IDENTIFIER = com.example.Example"))
        XCTAssertTrue(summary.contains("TARGETED_DEVICE_FAMILY = 1 2"))
    }
}
