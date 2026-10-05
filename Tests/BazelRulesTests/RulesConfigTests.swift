import Starlark
import Testing
@testable import BazelRules

struct RulesConfigTests {
    @Test
    func testConfigModule() {
        #expect(
            Rules.Config.bool_flag.module
                == "@bazel_skylib//rules:common_settings.bzl")
    }

    @Test
    func testBoolFlagTypedCall() {
        let call = Rules.Config.Call.bool_flag(
            name: "feature_enabled",
            build_setting_default: true,
            scope: "universal",
            visibility: .public)

        #expect(
            call.text
                == """
                bool_flag(
                    name = "feature_enabled",
                    build_setting_default = True,
                    scope = "universal",
                    visibility = [
                        "//visibility:public",
                    ],
                )
                """)
    }

    @Test
    func testStringFlagTypedCall() {
        let call = Rules.Config.Call.string_flag(
            name: "flavor",
            build_setting_default: "debug",
            make_variable: "FLAVOR",
            scope: "universal",
            values: ["debug", "release"])

        #expect(
            call.text
                == """
                string_flag(
                    name = "flavor",
                    build_setting_default = "debug",
                    make_variable = "FLAVOR",
                    scope = "universal",
                    values = [
                        "debug",
                        "release",
                    ],
                )
                """)
    }

    @Test
    func testStringListSettingTypedCall() {
        let call = Rules.Config.Call.string_list_setting(
            name: "enabled_features",
            build_setting_default: ["a", "b"])

        #expect(
            call.text
                == """
                string_list_setting(
                    name = "enabled_features",
                    build_setting_default = [
                        "a",
                        "b",
                    ],
                )
                """)
    }

    @Test
    func testBuiltinConfigSettingCall() {
        let call = Rules.Builtin.Call.config_setting(
            name: "Debug",
            values: ["compilation_mode": "dbg"],
            flag_values: [":mode": "Debug"])

        #expect(
            call.text
                == """
                config_setting(
                    name = "Debug",
                    values = {
                        "compilation_mode": "dbg",
                    },
                    flag_values = {
                        ":mode": "Debug",
                    },
                )
                """)
    }

    @Test
    func testBuiltinConstraintCalls() {
        let setting = Rules.Builtin.Call.constraint_setting(
            name: "unsupported_platform")
        let value = Rules.Builtin.Call.constraint_value(
            name: "driverkit",
            constraint_setting: ":unsupported_platform",
            visibility: .public)

        #expect(
            setting.text
                == """
                constraint_setting(
                    name = "unsupported_platform",
                )
                """)
        #expect(
            value.text
                == """
                constraint_value(
                    name = "driverkit",
                    constraint_setting = ":unsupported_platform",
                    visibility = [
                        "//visibility:public",
                    ],
                )
                """)
    }

    @Test
    func testBoolSettingTypedCall() {
        let call = Rules.Config.Call.bool_setting(
            name: "strict",
            build_setting_default: true)

        #expect(
            call.text
                == """
                bool_setting(
                    name = "strict",
                    build_setting_default = True,
                )
                """)
    }

    @Test
    func testIntFlagTypedCall() {
        let call = Rules.Config.Call.int_flag(
            name: "jobs",
            build_setting_default: 4)

        #expect(
            call.text
                == """
                int_flag(
                    name = "jobs",
                    build_setting_default = 4,
                )
                """)
    }

    @Test
    func testIntSettingTypedCall() {
        let call = Rules.Config.Call.int_setting(
            name: "level",
            build_setting_default: 2)

        #expect(
            call.text
                == """
                int_setting(
                    name = "level",
                    build_setting_default = 2,
                )
                """)
    }

    @Test
    func testStringSettingTypedCall() {
        let call = Rules.Config.Call.string_setting(
            name: "mode",
            build_setting_default: "Debug",
            values: ["Debug", "Release"])

        #expect(
            call.text
                == """
                string_setting(
                    name = "mode",
                    build_setting_default = "Debug",
                    values = [
                        "Debug",
                        "Release",
                    ],
                )
                """)
    }

    @Test
    func testStringListFlagTypedCall() {
        let call = Rules.Config.Call.string_list_flag(
            name: "traits",
            build_setting_default: ["Fast", "Slow"])

        #expect(
            call.text
                == """
                string_list_flag(
                    name = "traits",
                    build_setting_default = [
                        "Fast",
                        "Slow",
                    ],
                )
                """)
    }
}
