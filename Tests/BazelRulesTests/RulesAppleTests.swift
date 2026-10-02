import Starlark
import Testing
@testable import BazelRules

struct RulesAppleTests {
    @Test
    func testIOSModule() {
        #expect(
            Rules.Apple.IOS.ios_application.module
                == "@build_bazel_rules_apple//apple:ios.bzl")
    }

    @Test
    func testIOSApplicationTypedCall() {
        let call = Rules.Apple.IOS.Call.ios_application(
            name: "App",
            bundle_id: "com.example.app",
            deps: [":App_library"],
            families: ["iphone"],
            infoplists: [":Info.plist"],
            minimum_os_version: "18.0",
            sdk_frameworks: ["UIKit"],
            strings: [":Strings"],
            visibility: .public)

        #expect(
            call.text
                == """
                ios_application(
                    name = "App",
                    bundle_id = "com.example.app",
                    deps = [
                        ":App_library",
                    ],
                    families = [
                        "iphone",
                    ],
                    infoplists = [
                        ":Info.plist",
                    ],
                    minimum_os_version = "18.0",
                    sdk_frameworks = [
                        "UIKit",
                    ],
                    strings = [
                        ":Strings",
                    ],
                    visibility = [
                        "//visibility:public",
                    ],
                )
                """)
    }

    @Test
    func testIOSUnitTestTypedCall() {
        let call = Rules.Apple.IOS.Call.ios_unit_test(
            name: "AppTests",
            deps: [":AppTests_library"],
            minimum_os_version: "18.0",
            test_host: "//App:App")

        #expect(
            call.text
                == """
                ios_unit_test(
                    name = "AppTests",
                    deps = [
                        ":AppTests_library",
                    ],
                    minimum_os_version = "18.0",
                    test_host = "//App:App",
                )
                """)
    }

    @Test
    func testIOSUITestTypedCall() {
        let call = Rules.Apple.IOS.Call.ios_ui_test(
            name: "AppUITests",
            deps: [":AppUITests_library"],
            minimum_os_version: "18.0",
            test_host: "//App:App",
            visibility: .public)

        #expect(
            call.text
                == """
                ios_ui_test(
                    name = "AppUITests",
                    deps = [
                        ":AppUITests_library",
                    ],
                    minimum_os_version = "18.0",
                    test_host = "//App:App",
                    visibility = [
                        "//visibility:public",
                    ],
                )
                """)
    }

    @Test
    func testMacOSCommandLineApplicationTypedCall() {
        let call = Rules.Apple.MacOS.Call.macos_command_line_application(
            name: "CLI",
            bundle_id: "com.example.cli",
            deps: [":CLI_library"],
            infoplists: [":Info.plist"],
            minimum_os_version: "15.0")

        #expect(
            call.text
                == """
                macos_command_line_application(
                    name = "CLI",
                    bundle_id = "com.example.cli",
                    deps = [
                        ":CLI_library",
                    ],
                    infoplists = [
                        ":Info.plist",
                    ],
                    minimum_os_version = "15.0",
                )
                """)
    }

    @Test
    func testTVOSUnitTestTypedCall() {
        let call = Rules.Apple.TVOS.Call.tvos_unit_test(
            name: "TVTests",
            deps: [":TVTests_library"],
            minimum_os_version: "18.0")

        #expect(
            call.text
                == """
                tvos_unit_test(
                    name = "TVTests",
                    deps = [
                        ":TVTests_library",
                    ],
                    minimum_os_version = "18.0",
                )
                """)
    }

    @Test
    func testWatchOSApplicationTypedCall() {
        let call = Rules.Apple.WatchOS.Call.watchos_application(
            name: "WatchApp",
            bundle_id: "com.example.watch",
            deps: [":WatchApp_library"],
            minimum_os_version: "11.0")

        #expect(
            call.text
                == """
                watchos_application(
                    name = "WatchApp",
                    bundle_id = "com.example.watch",
                    deps = [
                        ":WatchApp_library",
                    ],
                    minimum_os_version = "11.0",
                )
                """)
    }

    @Test
    func testAppleStaticLibraryTypedCall() {
        let call = Rules.Apple.General.Call.apple_static_library(
            name: "StaticLib",
            deps: [":Core"],
            platform_type: "ios",
            sdk_frameworks: ["UIKit"])

        #expect(
            call.text
                == """
                apple_static_library(
                    name = "StaticLib",
                    deps = [
                        ":Core",
                    ],
                    platform_type = "ios",
                    sdk_frameworks = [
                        "UIKit",
                    ],
                )
                """)
    }

    @Test
    func testAppleDynamicFrameworkImportTypedCall() {
        let call = Rules.Apple.General.Call.apple_dynamic_framework_import(
            name: "FrameworkImport",
            framework_imports: Starlark.glob(["Vendor/My.framework/**"]),
            visibility: .public)

        #expect(
            call.text
                == """
                apple_dynamic_framework_import(
                    name = "FrameworkImport",
                    framework_imports = glob([
                        "Vendor/My.framework/**",
                    ]),
                    visibility = [
                        "//visibility:public",
                    ],
                )
                """)
    }

    @Test
    func testAppleDynamicXCFrameworkImportTypedCall() {
        let call = Rules.Apple.General.Call.apple_dynamic_xcframework_import(
            name: "XCFrameworkImport",
            xcframework_imports: Starlark.glob(["Vendor/My.xcframework/**"]),
            visibility: .public)

        #expect(
            call.text
                == """
                apple_dynamic_xcframework_import(
                    name = "XCFrameworkImport",
                    xcframework_imports = glob([
                        "Vendor/My.xcframework/**",
                    ]),
                    visibility = [
                        "//visibility:public",
                    ],
                )
                """)
    }

    @Test
    func testAppleStaticFrameworkImportTypedCall() {
        let call = Rules.Apple.General.Call.apple_static_framework_import(
            name: "FrameworkImport",
            framework_imports: Starlark.glob(["Vendor/My.framework/**"]),
            visibility: .public)

        #expect(
            call.text
                == """
                apple_static_framework_import(
                    name = "FrameworkImport",
                    framework_imports = glob([
                        "Vendor/My.framework/**",
                    ]),
                    visibility = [
                        "//visibility:public",
                    ],
                )
                """)
    }

    @Test
    func testAppleStaticXCFrameworkImportTypedCall() {
        let call = Rules.Apple.General.Call.apple_static_xcframework_import(
            name: "XCFrameworkImport",
            xcframework_imports: Starlark.glob(["Vendor/My.xcframework/**"]),
            visibility: .public)

        #expect(
            call.text
                == """
                apple_static_xcframework_import(
                    name = "XCFrameworkImport",
                    xcframework_imports = glob([
                        "Vendor/My.xcframework/**",
                    ]),
                    visibility = [
                        "//visibility:public",
                    ],
                )
                """)
    }

    @Test
    func testAppleResourceBundleTypedCall() {
        let call = Rules.Apple.Resources.Call.apple_resource_bundle(
            name: "Assets",
            resources: [":Images.xcassets"])

        #expect(
            call.text
                == """
                apple_resource_bundle(
                    name = "Assets",
                    resources = [
                        ":Images.xcassets",
                    ],
                )
                """)
    }

    @Test
    func testAppleBundleVersionTypedCall() {
        let call = Rules.Apple.Versioning.Call.apple_bundle_version(
            name: "Version",
            build_version: "1",
            short_version_string: "1.0")

        #expect(
            call.text
                == """
                apple_bundle_version(
                    name = "Version",
                    build_version = "1",
                    short_version_string = "1.0",
                )
                """)
    }

    @Test
    func testXCArchiveTypedCall() {
        let call = Rules.Apple.Packaging.Call.xcarchive(
            name: "AppArchive",
            bundle_name: "App",
            target: "//App:App")

        #expect(
            call.text
                == """
                xcarchive(
                    name = "AppArchive",
                    bundle_name = "App",
                    target = "//App:App",
                )
                """)
    }

    @Test
    func testIOSExtensionTypedCall() {
        let call = Rules.Apple.IOS.Call.ios_extension(
            name: "ShareExt",
            bundle_id: "com.example.share",
            deps: [":ShareExt_library"],
            entitlements: "Sources/ShareExt/ShareExt.entitlements",
            families: ["iphone", "ipad"],
            minimum_os_version: "18.0")

        #expect(
            call.text
                == """
                ios_extension(
                    name = "ShareExt",
                    bundle_id = "com.example.share",
                    deps = [
                        ":ShareExt_library",
                    ],
                    entitlements = "Sources/ShareExt/ShareExt.entitlements",
                    families = [
                        "iphone",
                        "ipad",
                    ],
                    minimum_os_version = "18.0",
                )
                """)
    }

    @Test
    func testIOSUnitTestSuiteTypedCall() {
        let call = Rules.Apple.IOS.Call.ios_unit_test_suite(
            name: "UnitSuite",
            minimum_os_version: "18.0",
            runners: [":Runner"])

        #expect(
            call.text
                == """
                ios_unit_test_suite(
                    name = "UnitSuite",
                    minimum_os_version = "18.0",
                    runners = [
                        ":Runner",
                    ],
                )
                """)
    }

    @Test
    func testMacOSBuildTestTypedCall() {
        let call = Rules.Apple.MacOS.Call.macos_build_test(
            name: "BuildCheck",
            minimum_os_version: "15.0",
            targets: ["//App:App"])

        #expect(
            call.text
                == """
                macos_build_test(
                    name = "BuildCheck",
                    minimum_os_version = "15.0",
                    targets = [
                        "//App:App",
                    ],
                )
                """)
    }

    @Test
    func testIOSIMessageApplicationTypedCall() {
        let call = Rules.Apple.IOS.Call.ios_imessage_application(
            name: "Stickers",
            bundle_id: "com.example.stickers",
            extensions: ["//Targets/StickerPack:StickerPack"],
            families: ["iphone"],
            minimum_os_version: "18.0")

        #expect(
            call.text
                == """
                ios_imessage_application(
                    name = "Stickers",
                    bundle_id = "com.example.stickers",
                    extensions = [
                        "//Targets/StickerPack:StickerPack",
                    ],
                    families = [
                        "iphone",
                    ],
                    minimum_os_version = "18.0",
                )
                """)
    }

    @Test
    func testIOSIMessageExtensionTypedCall() {
        let call = Rules.Apple.IOS.Call.ios_imessage_extension(
            name: "StickerExt",
            bundle_id: "com.example.stickers.ext",
            deps: [":StickerExt_library"],
            minimum_os_version: "18.0")

        #expect(
            call.text
                == """
                ios_imessage_extension(
                    name = "StickerExt",
                    bundle_id = "com.example.stickers.ext",
                    deps = [
                        ":StickerExt_library",
                    ],
                    minimum_os_version = "18.0",
                )
                """)
    }

    @Test
    func testIOSStickerPackExtensionTypedCall() {
        let call = Rules.Apple.IOS.Call.ios_sticker_pack_extension(
            name: "Pack",
            bundle_id: "com.example.stickers.pack",
            minimum_os_version: "18.0",
            sticker_assets: ["Sources/Pack/Stickers.xcassets"])

        #expect(
            call.text
                == """
                ios_sticker_pack_extension(
                    name = "Pack",
                    bundle_id = "com.example.stickers.pack",
                    minimum_os_version = "18.0",
                    sticker_assets = [
                        "Sources/Pack/Stickers.xcassets",
                    ],
                )
                """)
    }

    @Test
    func testMacOSBundleTypedCall() {
        let call = Rules.Apple.MacOS.Call.macos_bundle(
            name: "Plugin",
            bundle_extension: "prefPane",
            bundle_id: "com.example.plugin",
            deps: [":Plugin_library"],
            minimum_os_version: "15.0")

        #expect(
            call.text
                == """
                macos_bundle(
                    name = "Plugin",
                    bundle_extension = "prefPane",
                    bundle_id = "com.example.plugin",
                    deps = [
                        ":Plugin_library",
                    ],
                    minimum_os_version = "15.0",
                )
                """)
    }

    @Test
    func testMacOSKernelExtensionTypedCall() {
        let call = Rules.Apple.MacOS.Call.macos_kernel_extension(
            name: "Driver",
            bundle_id: "com.example.driver",
            deps: [":Driver_library"],
            minimum_os_version: "15.0")

        #expect(
            call.text
                == """
                macos_kernel_extension(
                    name = "Driver",
                    bundle_id = "com.example.driver",
                    deps = [
                        ":Driver_library",
                    ],
                    minimum_os_version = "15.0",
                )
                """)
    }

    @Test
    func testMacOSQuickLookPluginTypedCall() {
        let call = Rules.Apple.MacOS.Call.macos_quick_look_plugin(
            name: "Preview",
            additional_contents: ["//Targets/Helper:Helper": "Helpers"],
            bundle_id: "com.example.preview",
            deps: [":Preview_library"],
            minimum_os_version: "15.0")

        #expect(
            call.text
                == """
                macos_quick_look_plugin(
                    name = "Preview",
                    additional_contents = {
                        "//Targets/Helper:Helper": "Helpers",
                    },
                    bundle_id = "com.example.preview",
                    deps = [
                        ":Preview_library",
                    ],
                    minimum_os_version = "15.0",
                )
                """)
    }

    @Test
    func testMacOSSpotlightImporterTypedCall() {
        let call = Rules.Apple.MacOS.Call.macos_spotlight_importer(
            name: "Importer",
            bundle_id: "com.example.importer",
            deps: [":Importer_library"],
            minimum_os_version: "15.0")

        #expect(
            call.text
                == """
                macos_spotlight_importer(
                    name = "Importer",
                    bundle_id = "com.example.importer",
                    deps = [
                        ":Importer_library",
                    ],
                    minimum_os_version = "15.0",
                )
                """)
    }

    @Test
    func testIOSAppClipTypedCall() {
        let call = Rules.Apple.IOS.Call.ios_app_clip(
            name: "Clip",
            bundle_id: "com.example.app.Clip",
            deps: [":Clip_library"],
            minimum_os_version: "18.0")

        #expect(
            call.text
                == """
                ios_app_clip(
                    name = "Clip",
                    bundle_id = "com.example.app.Clip",
                    deps = [
                        ":Clip_library",
                    ],
                    minimum_os_version = "18.0",
                )
                """)
    }

    @Test
    func testTVOSExtensionTypedCall() {
        let call = Rules.Apple.TVOS.Call.tvos_extension(
            name: "TopShelf",
            bundle_id: "com.example.tv.TopShelf",
            deps: [":TopShelf_library"],
            minimum_os_version: "18.0")

        #expect(
            call.text
                == """
                tvos_extension(
                    name = "TopShelf",
                    bundle_id = "com.example.tv.TopShelf",
                    deps = [
                        ":TopShelf_library",
                    ],
                    minimum_os_version = "18.0",
                )
                """)
    }

    @Test
    func testWatchOSExtensionTypedCall() {
        let call = Rules.Apple.WatchOS.Call.watchos_extension(
            name: "Complication",
            bundle_id: "com.example.watch.Complication",
            deps: [":Complication_library"],
            minimum_os_version: "11.0")

        #expect(
            call.text
                == """
                watchos_extension(
                    name = "Complication",
                    bundle_id = "com.example.watch.Complication",
                    deps = [
                        ":Complication_library",
                    ],
                    minimum_os_version = "11.0",
                )
                """)
    }

    @Test
    func testMacOSDylibTypedCall() {
        let call = Rules.Apple.MacOS.Call.macos_dylib(
            name: "libHelper",
            bundle_id: "com.example.helper",
            deps: [":Helper_library"],
            minimum_os_version: "15.0")

        #expect(
            call.text
                == """
                macos_dylib(
                    name = "libHelper",
                    bundle_id = "com.example.helper",
                    deps = [
                        ":Helper_library",
                    ],
                    minimum_os_version = "15.0",
                )
                """)
    }

    @Test
    func testMacOSDynamicFrameworkTypedCall() {
        let call = Rules.Apple.MacOS.Call.macos_dynamic_framework(
            name: "Shared",
            bundle_id: "com.example.shared",
            deps: [":Shared_library"],
            minimum_os_version: "15.0")

        #expect(
            call.text
                == """
                macos_dynamic_framework(
                    name = "Shared",
                    bundle_id = "com.example.shared",
                    deps = [
                        ":Shared_library",
                    ],
                    minimum_os_version = "15.0",
                )
                """)
    }

    @Test
    func testMacOSStaticFrameworkTypedCall() {
        let call = Rules.Apple.MacOS.Call.macos_static_framework(
            name: "Core",
            avoid_deps: [":Logging"],
            deps: [":Core_library"],
            minimum_os_version: "15.0")

        #expect(
            call.text
                == """
                macos_static_framework(
                    name = "Core",
                    avoid_deps = [
                        ":Logging",
                    ],
                    deps = [
                        ":Core_library",
                    ],
                    minimum_os_version = "15.0",
                )
                """)
    }

    @Test
    func testAppleStaticXCFrameworkTypedCall() {
        let call = Rules.Apple.General.Call.apple_static_xcframework(
            name: "CoreKit",
            deps: [":Core_library"],
            minimum_os_versions: ["ios": "16.0"],
            public_hdrs: ["include/Core.h"])

        #expect(
            call.text
                == """
                apple_static_xcframework(
                    name = "CoreKit",
                    deps = [
                        ":Core_library",
                    ],
                    minimum_os_versions = {
                        "ios": "16.0",
                    },
                    public_hdrs = [
                        "include/Core.h",
                    ],
                )
                """)
    }

    @Test
    func testLocalProvisioningProfileTypedCall() {
        let call = Rules.Apple.General.Call.local_provisioning_profile(
            name: "development",
            profile_name: "iOS Team Provisioning Profile: com.example.app",
            teamid: "A1B2C3D4E5")

        #expect(
            call.text
                == """
                local_provisioning_profile(
                    name = "development",
                    profile_name = "iOS Team Provisioning Profile: com.example.app",
                    teamid = "A1B2C3D4E5",
                )
                """)
    }

    @Test
    func testProvisioningProfileRepositoryTypedCall() {
        let call = Rules.Apple.General.Call.provisioning_profile_repository(
            name: "local_provisioning_profiles",
            fallback_profiles: "//profiles:fallback")

        #expect(
            call.text
                == """
                provisioning_profile_repository(
                    name = "local_provisioning_profiles",
                    fallback_profiles = "//profiles:fallback",
                )
                """)
    }

    @Test
    func testProvisioningProfileRepositoryExtensionTypedCall() {
        let call = Rules.Apple.General.Call.provisioning_profile_repository_extension(
            name: "local_provisioning_profiles")

        #expect(
            call.text
                == """
                provisioning_profile_repository_extension(
                    name = "local_provisioning_profiles",
                )
                """)
    }
}
