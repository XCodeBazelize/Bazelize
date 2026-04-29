import Testing
@testable import XCode2

struct BuildSettingsTests {
    @Test
    func buildSettingsHelpersExposeSemanticValues() {
        let settings = XCode.BuildSettings(
            name: "Debug",
            setting: [
                "PRODUCT_BUNDLE_IDENTIFIER": "com.example.app",
                "TARGETED_DEVICE_FAMILY": "1 2",
            ]
        )

        #expect(settings.metadata.bundleID == "com.example.app")
        #expect(settings.platform.deviceFamily.map(\.code) == ["iphone", "ipad"])
    }

    @Test
    func buildSettingsPlistHelpersReadExpectedKeys() {
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

        #expect(settings.generatedPlist.enabled)
        #expect(settings.plist.infoPlist == "App/Info.plist")
        #expect(settings.plist.launch == "LaunchScreen")
        #expect(settings.plist.storyboard == "Main")
        #expect(settings.generatedPlist.currentProjectVersion == "42")
        #expect(settings.generatedPlist.marketingVersion == "2.3")
    }

    @Test
    func buildSettingsPlatformHelpersReadDeploymentTargets() {
        let settings = XCode.BuildSettings(
            name: "Release",
            setting: [
                "IPHONEOS_DEPLOYMENT_TARGET": "16.0",
                "MACOSX_DEPLOYMENT_TARGET": "14.0",
                "WATCHOS_DEPLOYMENT_TARGET": "10.0",
            ]
        )

        #expect(settings.platform.iOS == "16.0")
        #expect(settings.platform.macOS == "14.0")
        #expect(settings.platform.tvOS == nil)
        #expect(
            settings.platform.deploymentTargets ==
                ["iOS": "16.0", "macOS": "14.0", "watchOS": "10.0"]
        )
    }

    @Test
    func buildSettingsPlatformHelpersReadAppleFamiliesLiteral() {
        let settings = XCode.BuildSettings(
            name: "Release",
            setting: [
                "TARGETED_DEVICE_FAMILY": "1 2",
            ]
        )

        #expect(settings.platform.deviceFamily.map(\.code) == ["iphone", "ipad"])
        #expect(settings.platform.appleFamiliesLiteral == #"["iphone", "ipad"]"#)
    }

    @Test
    func buildSettingsMetadataHelpersReadExpectedKeys() {
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

        #expect(settings.metadata.bundleID == "com.example.app")
        #expect(settings.metadata.moduleName == "ExampleModule")
        #expect(settings.metadata.productName == "ExampleApp")
        #expect(settings.metadata.developmentTeam == "TEAM123")
        #expect(settings.metadata.codeSignStyle == "Automatic")
        #expect(settings.metadata.codeSignIdentity == "Apple Development")
    }

    @Test
    func buildSettingsPlistEntriesRenderCommonInfoPlistKeys() {
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

        #expect(plist.contains("<key>UILaunchStoryboardName</key>"))
        #expect(plist.contains("<string>LaunchScreen</string>"))
        #expect(plist.contains("<key>UISupportedInterfaceOrientations</key>"))
        #expect(plist.contains("<string>UIInterfaceOrientationPortrait</string>"))
        #expect(plist.contains("<string>UIInterfaceOrientationLandscapeLeft</string>"))
        #expect(plist.contains("<key>UIApplicationSupportsIndirectInputEvents</key>"))
        #expect(plist.contains("<true/>"))
    }
}
