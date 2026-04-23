import Testing
@testable import BazelRules
import RuleBuilder

struct RulesConfigTests {
    @Test
    func testConfigModule() {
        #expect(
            Rules.Config.bool_flag.module
                == "@bazel_skylib//rules:common_settings.bzl"
        )
    }

    @Test
    func testBoolFlagTypedCall() {
        let call = Rules.Config.Call.bool_flag(
            name: "feature_enabled",
            build_setting_default: true,
            scope: "universal",
            visibility: Starlark.Statement.Argument.Visibility.public
        )

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
                """
        )
    }

    @Test
    func testStringFlagTypedCall() {
        let call = Rules.Config.Call.string_flag(
            name: "flavor",
            build_setting_default: "debug",
            make_variable: "FLAVOR",
            scope: "universal",
            values: ["debug", "release"]
        )

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
                """
        )
    }

    @Test
    func testStringListSettingTypedCall() {
        let call = Rules.Config.Call.string_list_setting(
            name: "enabled_features",
            build_setting_default: ["a", "b"]
        )

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
                """
        )
    }
}
