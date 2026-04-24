import Testing
@testable import BazelRules
import RuleBuilder

struct RulesObjcTests {
    @Test
    func testObjcModule() {
        #expect(
            Rules.Objc.objc_library.module
                == "@rules_cc//cc:defs.bzl"
        )
    }

    @Test
    func testObjcLibraryTypedCall() {
        let call = Rules.Objc.Call.objc_library(
            name: "CoreObjC",
            srcs: ["A.m"],
            hdrs: ["A.h"],
            deps: ["//Lib:Support"],
            sdk_frameworks: ["UIKit"],
            visibility: .public
        )

        #expect(
            call.text
                == """
                objc_library(
                    name = "CoreObjC",
                    srcs = [
                        "A.m",
                    ],
                    hdrs = [
                        "A.h",
                    ],
                    deps = [
                        "//Lib:Support",
                    ],
                    sdk_frameworks = [
                        "UIKit",
                    ],
                    visibility = [
                        "//visibility:public",
                    ],
                )
                """
        )
    }

    @Test
    func testAvailableXcodesTypedCall() {
        let call = Rules.Objc.Call.available_xcodes(
            name: "xcodes",
            default: ":xcode_16",
            versions: [":xcode_16", ":xcode_15"]
        )

        #expect(
            call.text
                == """
                available_xcodes(
                    name = "xcodes",
                    default = ":xcode_16",
                    versions = [
                        ":xcode_16",
                        ":xcode_15",
                    ],
                )
                """
        )
    }

    @Test
    func testXcodeVersionTypedCall() {
        let call = Rules.Objc.Call.xcode_version(
            name: "xcode_16",
            version: "16.0",
            aliases: ["16", "16.0"],
            default_ios_sdk_version: "18.0"
        )

        #expect(
            call.text
                == """
                xcode_version(
                    name = "xcode_16",
                    version = "16.0",
                    aliases = [
                        "16",
                        "16.0",
                    ],
                    default_ios_sdk_version = "18.0",
                )
                """
        )
    }
}
