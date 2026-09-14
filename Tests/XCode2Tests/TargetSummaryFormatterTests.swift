import Testing
@testable import XCode2

struct TargetSummaryFormatterTests {
    @Test
    func formatTargetSummary() throws {
        let target = XCode.Target(
            name: "Example",
            productName: "Example",
            productType: "com.apple.product-type.application",
            preferConfig: "Release",
            configs: [
                "Debug": .init(
                    name: "Debug",
                    setting: [
                        "SWIFT_VERSION": "5.9",
                    ]),
                "Release": .init(
                    name: "Release",
                    setting: [
                        "INFOPLIST_FILE": "Example/Info.plist",
                        "IPHONEOS_DEPLOYMENT_TARGET": "16.0",
                        "PRODUCT_BUNDLE_IDENTIFIER": "com.example.Example",
                        "SWIFT_VERSION": "5.9",
                        "TARGETED_DEVICE_FAMILY": "1 2",
                    ]),
            ],
            metadata: .init(
                bundleID: "com.example.Example",
                moduleName: "Example",
                infoPlist: "Example/Info.plist",
                entitlements: "Example/Example.entitlements",
                deploymentTargets: ["iOS": "16.0"],
                codeSign: .init(
                    developmentTeam: nil,
                    codeSignStyle: "Automatic",
                    codeSignIdentity: nil)),
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
                        attributes: []),
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
                        attributes: []),
                ],
                frameworks: [
                    .init(
                        name: "SVProgressHUD.xcframework",
                        path: "Vendor/SVProgressHUD.xcframework",
                        fullPath: "/tmp/Vendor/SVProgressHUD.xcframework",
                        label: "//Prebuilt:SVProgressHUD",
                        fileType: "wrapper.xcframework",
                        sourceTree: "<group>",
                        buildPhase: "frameworks",
                        compilerFlags: nil,
                        attributes: []),
                ],
                copyFiles: [],
                others: []),
            dependencies: .init(
                targets: ["Framework1"],
                packageProducts: [
                    .init(
                        productName: "LocalLib1",
                        package: nil,
                        packagePath: "../Local1"),
                ],
                frameworks: ["//Prebuilt:SVProgressHUD"],
                sdkDylibs: [],
                sdkFrameworks: ["SwiftUI", "UIKit"],
                sdkFrameworkSearchPaths: [],
                weakSDKFrameworks: []))

        let project = XCode.Project(
            name: "Example",
            workspacePath: "/tmp",
            projectPath: "/tmp/Example.xcodeproj",
            preferConfig: "Release",
            configs: [:],
            packages: .init(remote: [], local: []),
            targets: [target])

        let summary = XCode.TargetSummaryFormatter.format(project: project, target: target)

        #expect(summary.contains("Target: Example"))
        #expect(summary.contains("Type: com.apple.product-type.application"))
        #expect(summary.contains("Bundle ID: com.example.Example"))
        #expect(summary.contains("Sources:"))
        #expect(summary.contains("- Example/ExampleApp.swift"))
        #expect(summary.contains("Resources:"))
        #expect(summary.contains("Dependencies:"))
        #expect(summary.contains("../Local1 / LocalLib1"))
        #expect(summary.contains("//Prebuilt:SVProgressHUD"))
        #expect(summary.contains("SDK Frameworks:"))
        #expect(summary.contains("Settings [Release]:"))
        #expect(summary.contains("PRODUCT_BUNDLE_IDENTIFIER = com.example.Example"))
        #expect(summary.contains("TARGETED_DEVICE_FAMILY = 1 2"))
    }
}
