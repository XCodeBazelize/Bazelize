import Starlark
import Testing
@testable import BazelRules

struct RulesNativeTests {
    @Test
    func testNativeModule() {
        #expect(
            Rules.Native.native_binary.module
                == "@bazel_skylib//rules:native_binary.bzl")
    }

    @Test
    func testNativeBinaryTypedCall() {
        let call = Rules.Native.Call.native_binary(
            name: "GreetTool",
            src: "Artifacts/GreetTool/GreetTool.artifactbundle/bin/GreetTool",
            out: "GreetTool",
            data: Starlark.glob(["Artifacts/GreetTool/**"]),
            tags: ["manual"],
            visibility: .public)

        #expect(
            call.text
                == """
                native_binary(
                    name = "GreetTool",
                    src = "Artifacts/GreetTool/GreetTool.artifactbundle/bin/GreetTool",
                    out = "GreetTool",
                    data = glob([
                        "Artifacts/GreetTool/**",
                    ]),
                    tags = [
                        "manual",
                    ],
                    visibility = [
                        "//visibility:public",
                    ],
                )
                """)
    }
}
