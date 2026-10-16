load("@build_bazel_rules_apple//apple:macos.bzl", "macos_unit_test")
load("@build_bazel_rules_swift//swift:swift_binary.bzl", "swift_binary")
load("@build_bazel_rules_swift//swift:swift_library.bzl", "swift_library")
load("@rules_shell//shell:sh_binary.bzl", "sh_binary")

swift_binary(
    name = "Hello_plugin",
    copts = [
        "-I",
        "__BAZEL_SWIFT_TOOLCHAIN_PATH__/usr/lib/swift/pm/PluginAPI",
        "-package-description-version",
        "6.0.0",
    ],
    linkopts = [
        "-L",
        "__BAZEL_XCODE_DEVELOPER_DIR__/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/PluginAPI",
        "-lPackagePlugin",
        "-Wl,-rpath,/private/var/select/developer_dir/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/PluginAPI",
        "-Wl,-rpath,/var/db/xcode_select_link/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/PluginAPI",
    ],
    module_name = "Hello",
    srcs = glob([
        "Sources/Hello/**/*.swift",
    ]),
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
sh_binary(
    name = "hello_command",
    srcs = [
        "Generated/hello.sh",
    ],
    data = [
        ":Hello_plugin",
        "Generated/HelloCommand.json",
        "//:_plugin_host",
    ],
)
swift_library(
    name = "Greeting",
    alwayslink = True,
    always_include_developer_search_paths = True,
    copts = [
        "-DSWIFT_PACKAGE",
        "-Xcc",
        "-DSWIFT_PACKAGE",
    ],
    module_name = "Greeting",
    package_name = "CommandPlugin",
    srcs = glob([
        "Sources/Greeting/**/*.swift",
    ], exclude = [
        "Sources/Greeting/**/*.docc/**",
        "Sources/Greeting/**/*.xcprivacy/**",
    ], allow_empty = True),
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
swift_binary(
    name = "HelloTool",
    copts = [
        "-DSWIFT_PACKAGE",
        "-Xcc",
        "-DSWIFT_PACKAGE",
    ],
    module_name = "HelloTool",
    srcs = glob([
        "Sources/HelloTool/**/*.swift",
    ], exclude = [
        "Sources/HelloTool/**/*.docc/**",
        "Sources/HelloTool/**/*.xcprivacy/**",
    ], allow_empty = True),
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
swift_library(
    name = "GreetingTests_library",
    alwayslink = True,
    always_include_developer_search_paths = True,
    copts = [
        "-DSWIFT_PACKAGE",
        "-Xcc",
        "-DSWIFT_PACKAGE",
    ],
    module_name = "GreetingTests",
    package_name = "CommandPlugin",
    srcs = glob([
        "Sources/GreetingTests/**/*.swift",
    ], exclude = [
        "Sources/GreetingTests/**/*.docc/**",
        "Sources/GreetingTests/**/*.xcprivacy/**",
    ], allow_empty = True),
    deps = [
        ":Greeting",
    ],
    tags = [
        "manual",
    ],
    testonly = True,
    visibility = [
        "//visibility:private",
    ],
)
macos_unit_test(
    name = "GreetingTests",
    deps = [
        ":GreetingTests_library",
    ],
    minimum_os_version = "12.0",
    visibility = [
        "//visibility:public",
    ],
)
alias(
    name = "hello",
    actual = ":HelloTool",
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)