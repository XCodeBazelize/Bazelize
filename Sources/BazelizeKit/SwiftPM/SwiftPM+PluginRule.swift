//
//  SwiftPM+PluginRule.swift
//
//
//  Building a build tool plugin, and the command that runs it.
//

import BazelRules
import Foundation
@preconcurrency import PathKit
import Starlark
import Util

extension SwiftPM.Generator {
    /// A build tool plugin as a program Bazel builds.
    ///
    /// A plugin links nothing but the toolchain's `PackagePlugin`, so this is an
    /// ordinary `swift_binary` with the module on its search path. Building it
    /// here rather than with SwiftPM is what keeps the plugin path independent
    /// of whether the package it lives in builds at all — some toolchains
    /// cannot even load a package whose plugin names its tool by target.
    func buildPlugin(
        _ target: SwiftPM.PackageTarget,
        in package: SwiftPM.Package,
        prefix: String,
        builder: CodeBuilder)
    {
        guard let api = SwiftPM.PluginHost.pluginAPIPath else { return }

        builder.load(loadableRule: Rules.Swift.swift_binary)
        builder.call(
            Rules.Swift.Call.swift_binary(
                name: ruleName(of: target.name, in: package),
                copts: [
                    "-I", api,
                    /// Which `PackagePlugin` the plugin was written against; its
                    /// availability is stated in terms of the tools version.
                    "-package-description-version", package.manifest.toolsVersion,
                ].starlark,
                linkopts: [
                    "-L", api,
                    "-lPackagePlugin",
                    "-Xlinker", "-rpath", "-Xlinker", api,
                ].starlark,
                module_name: Self.moduleName(target.name),
                srcs: Starlark.glob(["\(prefix)/**/*.swift"]),
                tags: Self.manual,
                visibility: .public))
    }

    /// `bazel run //:tool`: everything the generated workspace can be asked or
    /// told, in one program.
    ///
    /// `list` answers out of text embedded when the workspace was generated,
    /// so asking never depends on whichever `bazelize` happens to be on
    /// `PATH`. `plugin` does depend on it, because running a plugin is what
    /// bazelize does that Bazel cannot: the plugins and the tools they run are
    /// `data` of this script, so running it builds them first — a script that
    /// called `bazel build` itself would be a second Bazel inside the first
    /// one's lock.
    ///
    /// Bazel has no extension point for custom commands, so `tools/bazel`
    /// keeps `bazel plugin` and `bazel list …` as aliases for it and forwards
    /// every other command unchanged.
    func writeWorkspaceTool(locals: [Path]) throws {
        let listings = [
            ("config", try Listing.config(output: output)),
            ("trait", Listing.traits(workspace: workspace)),
            ("language", Listing.languages(localizations)),
        ]

        let answers = listings.map { topic, contents in
            """
                \(topic))
                    cat <<'BAZELIZE_LIST'
            \(contents)
            BAZELIZE_LIST
                    ;;
            """
        }.joined(separator: "\n")

        let script = output + "tool.sh"
        try script.write("""
        #!/bin/bash
        # What this workspace can be asked about itself, and the one thing that
        # writes back into it.
        set -euo pipefail
        runfiles="${RUNFILES_DIR:-$0.runfiles}/_main"
        cd "${BUILD_WORKSPACE_DIRECTORY:-$(dirname "$0")}"

        usage() {
            cat >&2 <<'BAZELIZE_USAGE'
        Usage: bazel run //:tool -- <command>

          plugin                      run this workspace's build tool plugins,
                                      writing what they generate back into
                                      Packages/*/Generated/*Plugin
          list config                 the --config this workspace defines
          list trait                  the traits its packages declare
          list language               the localizations its packages ship
        BAZELIZE_USAGE
            exit 2
        }

        case "${1:-}" in
        plugin)
            \(pluginCommand(locals: locals))
            ;;
        list)
            case "${2:-}" in
        \(answers)
            *)
                usage
                ;;
            esac
            ;;
        *)
            usage
            ;;
        esac

        """)

        /// `sh_binary` refuses a script that is not executable.
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: script.string)

        let directory = output + "tools"
        try directory.mkpath()
        try writeBazelWrapper(to: directory + "bazel")
    }

    /// What `plugin` runs, and the filegroup of programs it needs built.
    ///
    /// A project with no packages has no plugin to run and no filegroup to
    /// name: the command says so rather than naming a label that does not
    /// resolve, which is a workspace that does not load.
    private func pluginCommand(locals: [Path]) throws -> String {
        guard (output + "Package.swift").exists else {
            return #"echo "This workspace has no Swift packages." >&2"#
        }

        let binaries = pluginBinaries

        try packagesRoot.mkpath()
        let group = CodeBuilder()
        group.call(
            Rules.Builtin.Call.filegroup(
                name: "plugins",
                srcs: .build { binaries.map(\.label).sorted().map { Starlark.Label.named($0) } },
                visibility: .public))
        /// The flags every trait is switched with, in the package the
        /// generator owns.
        buildTraitRules(group)
        try (packagesRoot + "BUILD").write(group.build())

        let arguments = ["--output", "."]
            + locals.flatMap { local in ["--local", local.absolute().string.quoted] }
            + binaries.flatMap { binary in
                [binary.isPlugin ? "--plugin" : "--tool", "\(binary.name)=$runfiles/\(binary.path)"]
            }

        return "exec bazelize plugins \(arguments.joined(separator: " "))"
    }

    private func writeBazelWrapper(to wrapper: Path) throws {
        try wrapper.write("""
        #!/bin/bash
        # Bazelisk runs this workspace wrapper and exposes Bazel as BAZEL_REAL.
        set -euo pipefail

        if [[ -z "${BAZEL_REAL:-}" ]]; then
            echo "tools/bazel ran without BAZEL_REAL: run Bazel through Bazelisk." >&2
            exit 1
        fi

        case "${1:-}" in
        plugin|list)
            exec "$BAZEL_REAL" run //:tool -- "$@"
            ;;
        esac

        exec "$BAZEL_REAL" "$@"

        """)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: wrapper.string)
    }

    /// What a plugin needs built: the plugin itself, and the tools it runs.
    private var pluginBinaries: [PluginBinary] {
        var binaries: [PluginBinary] = []

        for package in workspace.packages where package.isRoot || package.isLocal {
            let used = Set(package.manifest.targets.flatMap(\.pluginUsages).map(\.name))
            guard !used.isEmpty else { continue }

            for target in package.manifest.targets where used.contains(target.name) {
                guard target.type == "plugin" else { continue }
                binaries.append(binary(of: target, in: package, isPlugin: true))

                for dependency in target.dependencies {
                    guard case .target(let name) = dependency.kind else {
                        guard case .byName(let name) = dependency.kind else { continue }
                        if let tool = tool(named: name, in: package) { binaries.append(tool) }
                        continue
                    }
                    if let tool = tool(named: name, in: package) { binaries.append(tool) }
                }
            }
        }

        return binaries
    }

    private func tool(named name: String, in package: SwiftPM.Package) -> PluginBinary? {
        guard
            let target = package.manifest.targets.first(where: {
                $0.name == name && $0.type == "executable"
            })
        else {
            return nil
        }

        return binary(of: target, in: package, isPlugin: false)
    }

    private func binary(
        of target: SwiftPM.PackageTarget,
        in package: SwiftPM.Package,
        isPlugin: Bool) -> PluginBinary
    {
        let rule = ruleName(of: target.name, in: package)
        let directory = "\(PluginSwiftPM.packagesDirectory)/\(package.directory)"

        return .init(
            name: target.name,
            label: "//\(directory):\(rule)",
            path: "\(directory)/\(rule)",
            isPlugin: isPlugin)
    }
}

extension SwiftPM.Generator {
    /// A program `//:plugins` has Bazel build before it runs.
    struct PluginBinary {
        let name: String
        let label: String
        /// Where it sits in the runner's runfiles.
        let path: String
        let isPlugin: Bool
    }
}
