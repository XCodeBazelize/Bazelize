import BazelRules
import PathKit
import Starlark

extension SwiftPM.Generator {
    /// The attributes shared by the Apple resource rule and the standalone
    /// executable's materialized bundle.
    struct ResourceRule {
        let name: String
        let bundle: String
        let plist: String
        let resources: Starlark.Value?
    }

    /// Everything needed to write the language accessor after the resource rule.
    struct ResourceResult {
        let target: String
        let package: String
        let bundle: String
        let label: String
        let root: Path
        let kind: TargetKind
        let embeddedSource: String?
    }

    /// Emits either a propagated Apple resource provider or, for an executable,
    /// a concrete bundle directory that can travel in runfiles.
    func emit(
        _ rule: ResourceRule,
        executableMinimumOS: String?,
        builder: CodeBuilder)
    {
        guard let executableMinimumOS else {
            builder.load(loadableRule: Rules.Apple.Resources.apple_resource_bundle)
            builder.call(
                Rules.Apple.Resources.Call.apple_resource_bundle(
                    name: rule.name,
                    bundle_name: rule.bundle,
                    infoplists: .build { [Starlark.Label.named(rule.plist)] },
                    resources: rule.resources,
                    tags: Self.manual))
            return
        }

        /// `apple_resource_bundle` only propagates resources to another Apple
        /// bundler and has no output of its own. A standalone program has no such
        /// parent, so build an archive and expose its extracted directory.
        let archive = "\(rule.name)Archive"
        builder.load(.macos_bundle)
        builder.call(
            Rules.Apple.MacOS.Call.macos_bundle(
                name: archive,
                bundle_extension: "bundle",
                bundle_id: "org.swift.\(rule.bundle)",
                bundle_name: rule.bundle,
                infoplists: .build { [Starlark.Label.named(rule.plist)] },
                minimum_os_version: executableMinimumOS,
                resources: rule.resources,
                tags: Self.manual))

        builder.load(
            module: "//Packages:swiftpm_resource_bundle.bzl",
            symbols: ["swiftpm_resource_bundle"])
        builder.call(
            Starlark.Statement.Call("swiftpm_resource_bundle") {
                "name" => rule.name
                "archive" => Starlark.Label.named(":\(archive)")
                "bundle_name" => rule.bundle
                "tags" => Self.manual
            })
    }

    /// `Bundle.module`, the name a package's Swift code uses.
    ///
    /// An Apple bundle embeds the resource bundle beside its own resources. A
    /// standalone Bazel executable instead carries it in its runfiles tree, whose
    /// package-relative path is supplied for that target only.
    static func swiftAccessor(bundle: String, runfilesPath: String? = nil) -> String {
        let runfilesCandidates = runfilesPath.map {
            """

                    let environment = ProcessInfo.processInfo.environment
                    let workspace = environment["TEST_WORKSPACE"] ?? "_main"
                    let roots = [
                        environment["RUNFILES_DIR"],
                        environment["TEST_SRCDIR"],
                        Bundle.main.executableURL.map { $0.path + ".runfiles" },
                    ].compactMap { $0 }
                    candidates += roots.map {
                        URL(fileURLWithPath: $0)
                            .appendingPathComponent(workspace)
                            .appendingPathComponent("\($0)")
                    }
            """
        } ?? ""

        return """
        import Foundation

        private final class BundleFinder {}

        extension Foundation.Bundle {
            static let module: Bundle = {
                var candidates = [
                    Bundle.main.resourceURL,
                    Bundle(for: BundleFinder.self).resourceURL,
                    Bundle.main.bundleURL,
                ].compactMap { $0 }.map { $0.appendingPathComponent("\(bundle).bundle") }
        \(runfilesCandidates)

                for url in candidates {
                    if let bundle = Bundle(url: url) {
                        return bundle
                    }
                }

                fatalError("unable to find bundle named \(bundle)")
            }()
        }

        """
    }

    /// Extracts the archive produced by `macos_bundle` into a directory Bazel can
    /// carry as a runfile. The rule removes the empty executable that
    /// `macos_bundle` synthesizes: this is a resource bundle, not a loadable
    /// plug-in.
    static let resourceBundleRule = """
    'Materializes SwiftPM executable resource bundles as Bazel runfiles.'

    def _swiftpm_resource_bundle_impl(ctx):
        archive = ctx.file.archive
        bundle = ctx.actions.declare_directory(ctx.attr.bundle_name + ".bundle")
        ctx.actions.run_shell(
            inputs = [archive],
            outputs = [bundle],
            arguments = [archive.path, bundle.path, ctx.attr.bundle_name],
            command = '''
    set -euo pipefail
    temporary="$2.extract"
    rm -rf "$temporary"
    mkdir -p "$temporary" "$2"
    /usr/bin/unzip -q "$1" -d "$temporary"
    cp -R "$temporary/$3.bundle/." "$2/"
    rm -rf "$temporary" "$2/Contents/MacOS" "$2/Contents/_CodeSignature"
    /usr/libexec/PlistBuddy -c "Delete :CFBundleExecutable" "$2/Contents/Info.plist" >/dev/null
    ''',
        )
        return [DefaultInfo(
            files = depset([bundle]),
            runfiles = ctx.runfiles(files = [bundle]),
        )]

    swiftpm_resource_bundle = rule(
        implementation = _swiftpm_resource_bundle_impl,
        attrs = {
            "archive": attr.label(allow_single_file = [".zip"], mandatory = True),
            "bundle_name": attr.string(mandatory = True),
        },
    )
    """
}
