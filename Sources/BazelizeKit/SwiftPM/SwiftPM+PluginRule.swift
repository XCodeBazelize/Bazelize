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
                ],
                linkopts: [
                    "-L", api,
                    "-lPackagePlugin",
                    "-Xlinker", "-rpath", "-Xlinker", api,
                ],
                module_name: Self.moduleName(target.name),
                srcs: Starlark.glob(["\(prefix)/**/*.swift"]),
                tags: Self.manual,
                visibility: .public))
    }

    /// `bazel run //:plugins`, and everything it needs built first.
    ///
    /// The plugins and the tools they run are `data` of the script, so running
    /// it builds them: a script that called `bazel build` itself would be a
    /// second Bazel inside the first one's lock.
    func writePluginRunner(locals: [Path]) throws {
        /// The root `BUILD` declares `//:plugins` for any project with packages,
        /// because whether one of them has a plugin is not known when that file
        /// is written. So both of the things it names are written for any such
        /// project: a package with nothing to run is a command that does
        /// nothing, and a label that does not resolve is a workspace that does
        /// not load.
        guard (output + "Package.swift").exists else { return }

        let binaries = pluginBinaries

        try packagesRoot.mkpath()
        let group = CodeBuilder()
        group.call(
            Rules.Builtin.Call.filegroup(
                name: "plugins",
                srcs: .build { binaries.map(\.label).sorted().map { Starlark.Label.named($0) } },
                visibility: .public))
        try (packagesRoot + "BUILD").write(group.build())

        let arguments = ["--output", "."]
            + locals.flatMap { local in ["--local", local.absolute().string.quoted] }
            + binaries.flatMap { binary in
                [binary.isPlugin ? "--plugin" : "--tool", "\(binary.name)=$runfiles/\(binary.path)"]
            }

        let script = output + "plugins.sh"
        try script.write("""
        #!/bin/bash
        # Runs this workspace's build tool plugins, writing what they generate
        # back into `Packages/*/Generated/*Plugin`.
        #
        # The plugins and their tools are built by Bazel: they are `data` of this
        # script, so they are in its runfiles by the time it runs.
        set -euo pipefail
        runfiles="${RUNFILES_DIR:-$0.runfiles}/_main"
        cd "${BUILD_WORKSPACE_DIRECTORY:-$(dirname "$0")}"
        exec bazelize plugins \(arguments.joined(separator: " "))

        """)

        /// `sh_binary` refuses a script that is not executable.
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: script.string)
    }

    /// `bazel list config` and `bazel list trait`: what a generated workspace
    /// can be asked about itself.
    ///
    /// Bazel has no way to add a command, but its launcher does: Bazelisk runs
    /// `tools/bazel` instead of Bazel itself and hands it the real binary in
    /// `BAZEL_REAL`. So `list` is answered by the wrapper and everything else
    /// goes straight through — no server starts to print a list.
    ///
    /// It is written for every workspace: a project with no packages still has
    /// configurations, and packages that declare no trait is an answer too.
    func writeListCommand(locals: [Path]) throws {
        let directory = output + "tools"
        try directory.mkpath()

        /// `tools` is a package of its own, so nothing globs the wrapper into
        /// a rule of the workspace's root package.
        try (directory + "BUILD").write("# The `bazel` launcher's wrapper lives here, and is not a build input.\n")

        let arguments = locals
            .flatMap { local in ["--local", local.absolute().string.quoted] }
            .joined(separator: " ")

        let script = directory + "bazel"
        try script.write("""
        #!/bin/bash
        # The `bazel` this workspace runs: `bazel list config` says what
        # `--config=<name>` it defines, `bazel list trait` says which traits its
        # packages declare and which of them are on. Every other command is the
        # one Bazel would have run.
        set -euo pipefail
        workspace="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

        if [[ "${1:-}" == "list" ]]; then
            shift
            exec bazelize list "$@" --output "$workspace" \(arguments)
        fi

        if [[ -z "${BAZEL_REAL:-}" ]]; then
            echo "tools/bazel ran without BAZEL_REAL: run Bazel through Bazelisk." >&2
            exit 1
        fi

        exec "$BAZEL_REAL" "$@"

        """)

        /// The launcher only runs a wrapper it can execute.
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: script.string)
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

