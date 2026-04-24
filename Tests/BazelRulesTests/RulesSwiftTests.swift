import RuleBuilder
import Testing
@testable import BazelRules

struct RulesSwiftTests {
    @Test
    func testSwiftLibraryModule() {
        #expect(
            Rules.Swift.swift_library.module
                == "@build_bazel_rules_swift//swift:swift_library.bzl")
    }

    @Test
    func testSwiftCompilerPluginModule() {
        #expect(
            Rules.Swift.swift_compiler_plugin.module
                == "@build_bazel_rules_swift//swift:swift_compiler_plugin.bzl")
    }

    @Test
    func testSwiftOverlayModule() {
        #expect(
            Rules.Swift.swift_overlay.module
                == "@build_bazel_rules_swift//swift:swift_overlay.bzl")
    }

    @Test
    func testSwiftLibraryGroupModule() {
        #expect(
            Rules.Swift.swift_library_group.module
                == "@build_bazel_rules_swift//swift:swift_library_group.bzl")
    }

    @Test
    func testMixedLanguageLibraryModule() {
        #expect(
            Rules.Swift.mixed_language_library.module
                == "@build_bazel_rules_swift//mixed_language:mixed_language_library.bzl")
    }

    @Test
    func testSwiftLibraryCall() {
        let call = Rules.Swift.swift_library.call {
            "name" => "Core"
            "srcs" => ["A.swift"]
        }

        #expect(
            call.text
                == """
                swift_library(
                    name = "Core",
                    srcs = [
                        "A.swift",
                    ],
                )
                """)
    }

    @Test
    func testSwiftLibraryStatement() {
        let statement = Rules.Swift.swift_library.statement {
            "name" => "Core"
            "srcs" => ["A.swift"]
        }

        #expect(statement.text == Rules.Swift.swift_library.call {
            "name" => "Core"
            "srcs" => ["A.swift"]
        }.text)
    }

    @Test
    func testSwiftLibraryTypedCall() {
        let call = Rules.Swift.Call.swift_library(
            name: "Core",
            alwayslink: true,
            copts: ["-whole-module-optimization"],
            module_name: "CoreKit",
            srcs: ["A.swift"],
            deps: ["//Lib:Util"],
            data: [":Assets"],
            defines: ["DEBUG"],
            generated_header_name: "Core-Swift.h",
            generates_header: true,
            linkopts: ["-ObjC"],
            linkstatic: true,
            private_deps: ["//LibPrivate:Impl"],
            swiftc_inputs: [":Config.json"],
            testonly: true,
            visibility: .public)

        #expect(
            call.text
                == """
                swift_library(
                    name = "Core",
                    alwayslink = True,
                    copts = [
                        "-whole-module-optimization",
                    ],
                    module_name = "CoreKit",
                    srcs = [
                        "A.swift",
                    ],
                    deps = [
                        "//Lib:Util",
                    ],
                    data = [
                        ":Assets",
                    ],
                    defines = [
                        "DEBUG",
                    ],
                    generated_header_name = "Core-Swift.h",
                    generates_header = True,
                    linkopts = [
                        "-ObjC",
                    ],
                    linkstatic = True,
                    private_deps = [
                        "//LibPrivate:Impl",
                    ],
                    swiftc_inputs = [
                        ":Config.json",
                    ],
                    testonly = True,
                    visibility = [
                        "//visibility:public",
                    ],
                )
                """)
    }

    @Test
    func testSwiftLibraryTypedCallWithSelectDefines() {
        let call = Rules.Swift.Call.swift_library(
            name: "Core",
            srcs: ["A.swift"],
            defines: .select(
                .various([
                    .config("Debug"): ["DEBUG"],
                    .default: [],
                ])))

        #expect(
            call.text
                == """
                swift_library(
                    name = "Core",
                    alwayslink = True,
                    srcs = [
                        "A.swift",
                    ],
                    defines = select({
                        "//:Debug": [
                            "DEBUG",
                        ],
                        "//conditions:default": None
                    }),
                )
                """)
    }

    @Test
    func testSwiftBinaryTypedCall() {
        let call = Rules.Swift.Call.swift_binary(
            name: "CLI",
            copts: ["-DDEBUG"],
            deps: ["//Lib:Core"],
            linkopts: ["-ObjC"],
            module_name: "CLI",
            srcs: ["main.swift"],
            stamp: 1,
            swiftc_inputs: [":Config.json"],
            testonly: true,
            visibility: .public)

        #expect(
            call.text
                == """
                swift_binary(
                    name = "CLI",
                    copts = [
                        "-DDEBUG",
                    ],
                    deps = [
                        "//Lib:Core",
                    ],
                    linkopts = [
                        "-ObjC",
                    ],
                    module_name = "CLI",
                    srcs = [
                        "main.swift",
                    ],
                    stamp = 1,
                    swiftc_inputs = [
                        ":Config.json",
                    ],
                    testonly = True,
                    visibility = [
                        "//visibility:public",
                    ],
                )
                """)
    }

    @Test
    func testMixedLanguageLibraryTypedCallWithSelectDefines() {
        let call = Rules.Swift.Call.mixed_language_library(
            name: "Core",
            srcs: ["A.swift", "B.m"],
            defines: .select(
                .various([
                    .config("Debug"): ["DEBUG"],
                    .default: [],
                ])))

        #expect(
            call.text
                == """
                mixed_language_library(
                    name = "Core",
                    srcs = [
                        "A.swift",
                        "B.m",
                    ],
                    defines = select({
                        "//:Debug": [
                            "DEBUG",
                        ],
                        "//conditions:default": None
                    }),
                )
                """)
    }

    @Test
    func testSwiftTestTypedCall() {
        let call = Rules.Swift.Call.swift_test(
            name: "CoreTests",
            args: ["--filter", "CoreTests/testFoo"],
            copts: ["-DDEBUG"],
            data: [":Fixtures"],
            deps: ["//Lib:Core"],
            env: ["FOO": "BAR"],
            linkopts: ["-ObjC"],
            module_name: "CoreTests",
            srcs: ["CoreTests.swift"],
            stamp: 0,
            swiftc_inputs: [":Config.json"],
            visibility: .private)

        #expect(
            call.text
                == """
                swift_test(
                    name = "CoreTests",
                    args = [
                        "--filter",
                        "CoreTests/testFoo",
                    ],
                    copts = [
                        "-DDEBUG",
                    ],
                    data = [
                        ":Fixtures",
                    ],
                    deps = [
                        "//Lib:Core",
                    ],
                    env = {
                        "FOO": "BAR"
                    },
                    linkopts = [
                        "-ObjC",
                    ],
                    module_name = "CoreTests",
                    srcs = [
                        "CoreTests.swift",
                    ],
                    stamp = 0,
                    swiftc_inputs = [
                        ":Config.json",
                    ],
                    visibility = [
                        "//visibility:private",
                    ],
                )
                """)
    }

    @Test
    func testSwiftLibraryTypedStatementOmitsNilFields() {
        let statement = Starlark.Statement.call(
            Rules.Swift.Call.swift_library(
                name: "Core",
                srcs: ["A.swift"]))

        #expect(
            statement.text
                == """
                swift_library(
                    name = "Core",
                    alwayslink = True,
                    srcs = [
                        "A.swift",
                    ],
                )
                """)
    }
}
