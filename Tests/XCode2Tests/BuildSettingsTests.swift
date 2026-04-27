import XCTest
@testable import XCode2

final class BuildSettingsTests: XCTestCase {
    func testBuildSettingsSupportsStringAndArrayValues() {
        let settings = XCode.BuildSettings(
            name: "Debug",
            setting: [
                "PRODUCT_BUNDLE_IDENTIFIER": "com.example.app",
                "TARGETED_DEVICE_FAMILY": "1 2",
            ]
        )

        XCTAssertEqual(settings["PRODUCT_BUNDLE_IDENTIFIER"], "com.example.app")
        XCTAssertEqual(settings["TARGETED_DEVICE_FAMILY"], "1 2")
    }

    func testBuildSettingsPlistHelpersReadExpectedKeys() {
        let settings = XCode.BuildSettings(
            name: "Release",
            setting: [
                "GENERATE_INFOPLIST_FILE": "YES",
                "INFOPLIST_FILE": "App/Info.plist",
                "INFOPLIST_KEY_CFBundleDisplayName": "Example",
                "INFOPLIST_KEY_UILaunchStoryboardName": "LaunchScreen",
                "INFOPLIST_KEY_UIMainStoryboardFile": "Main",
                "CURRENT_PROJECT_VERSION": "42",
                "MARKETING_VERSION": "2.3",
            ]
        )

        XCTAssertTrue(settings.generatedPlist.enabled)
        XCTAssertEqual(settings.plist.infoPlist, "App/Info.plist")
        XCTAssertEqual(settings.plist.launch, "LaunchScreen")
        XCTAssertEqual(settings.plist.storyboard, "Main")
        XCTAssertEqual(settings.plist.keys, ["INFOPLIST_KEY_CFBundleDisplayName"])
        XCTAssertEqual(settings.generatedPlist.currentProjectVersion, "42")
        XCTAssertEqual(settings.generatedPlist.marketingVersion, "2.3")
    }

    func testBuildSettingsPlatformHelpersReadDeploymentTargets() {
        let settings = XCode.BuildSettings(
            name: "Release",
            setting: [
                "IPHONEOS_DEPLOYMENT_TARGET": "16.0",
                "MACOSX_DEPLOYMENT_TARGET": "14.0",
                "WATCHOS_DEPLOYMENT_TARGET": "10.0",
            ]
        )

        XCTAssertEqual(settings.platform.iOS, "16.0")
        XCTAssertEqual(settings.platform.macOS, "14.0")
        XCTAssertNil(settings.platform.tvOS)
        XCTAssertEqual(
            settings.platform.deploymentTargets,
            ["iOS": "16.0", "macOS": "14.0", "watchOS": "10.0"]
        )
    }

    func testBuildSettingsPlatformHelpersReadAppleFamiliesLiteral() {
        let settings = XCode.BuildSettings(
            name: "Release",
            setting: [
                "TARGETED_DEVICE_FAMILY": "1 2",
            ]
        )

        XCTAssertEqual(settings.platform.deviceFamily.map(\.code), ["iphone", "ipad"])
        XCTAssertEqual(settings.platform.appleFamiliesLiteral, #"[\"iphone\", \"ipad\"]"#)
    }

    func testBuildSettingsMetadataHelpersReadExpectedKeys() {
        let settings = XCode.BuildSettings(
            name: "Release",
            setting: [
                "PRODUCT_BUNDLE_IDENTIFIER": "com.example.app",
                "PRODUCT_MODULE_NAME": "ExampleModule",
                "PRODUCT_NAME": "ExampleApp",
                "DEVELOPMENT_TEAM": "TEAM123",
                "CODE_SIGN_STYLE": "Automatic",
                "CODE_SIGN_IDENTITY": "Apple Development",
            ]
        )

        XCTAssertEqual(settings.metadata.bundleID, "com.example.app")
        XCTAssertEqual(settings.metadata.moduleName, "ExampleModule")
        XCTAssertEqual(settings.metadata.productName, "ExampleApp")
        XCTAssertEqual(settings.metadata.developmentTeam, "TEAM123")
        XCTAssertEqual(settings.metadata.codeSignStyle, "Automatic")
        XCTAssertEqual(settings.metadata.codeSignIdentity, "Apple Development")
    }

    func testBuildSettingsPlistEntriesRenderCommonInfoPlistKeys() {
        let settings = XCode.BuildSettings(
            name: "Release",
            setting: [
                "GENERATE_INFOPLIST_FILE": "YES",
                "INFOPLIST_KEY_UILaunchStoryboardName": "LaunchScreen",
                "INFOPLIST_KEY_UISupportedInterfaceOrientations": "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft",
                "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
            ]
        )

        let plist = settings.generatedPlist.entries.joined(separator: "\n")

        XCTAssertTrue(plist.contains("<key>UILaunchStoryboardName</key>"))
        XCTAssertTrue(plist.contains("<string>LaunchScreen</string>"))
        XCTAssertTrue(plist.contains("<key>UISupportedInterfaceOrientations</key>"))
        XCTAssertTrue(plist.contains("<string>UIInterfaceOrientationPortrait</string>"))
        XCTAssertTrue(plist.contains("<string>UIInterfaceOrientationLandscapeLeft</string>"))
        XCTAssertTrue(plist.contains("<key>UIApplicationSupportsIndirectInputEvents</key>"))
        XCTAssertTrue(plist.contains("<true/>"))
    }
}
