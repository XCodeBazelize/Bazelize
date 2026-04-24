import RuleBuilder
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
}
