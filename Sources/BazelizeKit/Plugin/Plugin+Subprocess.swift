import Foundation
import Starlark

/// The generated macOS host uses the same subprocess implementation as Bazelize.
/// An isolated Bazel repository keeps its tools-only dependency out of the
/// consumer's SwiftPM resolution, traits, and deployment targets.
final class PluginSubprocess: PluginBuiltin {
    private var hasPackages: Bool {
        !kit.project.packages.remote.isEmpty || !kit.project.packages.local.isEmpty
    }

    override func module(_ builder: CodeBuilder) {
        guard hasPackages else { return }
        builder.custom("""
        subprocess_archive = use_repo_rule("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

        subprocess_archive(
            name = "bazelize_subprocess",
            build_file = "//tools/subprocess:subprocess.BUILD",
            sha256 = "ff2e777128a7ba9398a29f1da6f2c3d5295ac9fc9eef65bdfab6cdea9b827ded",
            strip_prefix = "swift-subprocess-b3937ab85dd32f6e9435914599c1519074769c1a",
            type = "tar.gz",
            urls = ["https://codeload.github.com/swiftlang/swift-subprocess/tar.gz/b3937ab85dd32f6e9435914599c1519074769c1a"],
        )
        """)
    }

    override var custom: [PluginBuiltin.Custom]? {
        guard hasPackages else { return nil }
        return [
            .init(path: "tools/subprocess/BUILD", content: "exports_files([\"subprocess.BUILD\"])\n"),
            .init(path: "tools/subprocess/subprocess.BUILD", content: Self.buildFile),
        ]
    }

    // Mirrors swift-subprocess 1.0.0's macOS target settings. Supported Xcode
    // toolchains supply System through their SDK; no consumer SwiftPM graph is
    // changed to provide the generated host's dependency.
    private static let buildFile = """
    load("@build_bazel_rules_swift//swift:swift.bzl", "swift_interop_hint", "swift_library")
    load("@rules_cc//cc:defs.bzl", "cc_library")

    swift_interop_hint(
        name = "shims_interop",
        module_name = "_SubprocessCShims",
    )

    cc_library(
        name = "_SubprocessCShims",
        srcs = ["Sources/_SubprocessCShims/process_shims.c"],
        hdrs = glob(["Sources/_SubprocessCShims/include/**/*.h"]),
        aspect_hints = [":shims_interop"],
        includes = ["Sources/_SubprocessCShims/include"],
    )

    swift_library(
        name = "Subprocess",
        package_name = "swift_subprocess",
        srcs = glob(["Sources/Subprocess/**/*.swift"]),
        copts = [
            "-swift-version",
            "6",
            "-enable-experimental-feature",
            "StrictConcurrency",
            "-enable-experimental-feature",
            "Lifetimes",
            "-enable-upcoming-feature",
            "ExistentialAny",
            "-enable-upcoming-feature",
            "MemberImportVisibility",
            "-enable-upcoming-feature",
            "InternalImportsByDefault",
            "-enable-upcoming-feature",
            "NonisolatedNonsendingByDefault",
        ],
        defines = [
            "SUBPROCESS_ASYNCIO_KQUEUE",
            "SubprocessFoundation",
        ],
        module_name = "Subprocess",
        target_compatible_with = ["@platforms//os:macos"],
        visibility = ["//visibility:public"],
        deps = [":_SubprocessCShims"],
    )
    """ + "\n"
}
