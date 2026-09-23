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

    /// Where a target's plugins write: beside the rules of the package that
    /// declares it, which is where every other generated file of that package
    /// already is.
    func pluginWorkDirectory(of target: SwiftPM.PackageTarget, in package: SwiftPM.Package) -> Path {
        output + PluginSwiftPM.packagesDirectory + package.directory + "Generated/\(target.name)Plugin"
    }

    /// `bazel run //:plugins`, and everything it needs built first.
    ///
    /// Bazel builds the host, plugins and tools. The generated plan contains
    /// each SwiftPM plugin request, so running this target never needs an
    /// installed `bazelize` executable.
    func writePluginRunner() throws {
        /// The root `BUILD` declares `//:plugins` for any project with packages,
        /// because whether one of them has a plugin is not known when that file
        /// is written. So all of its inputs exist even when the plan is empty.
        guard (output + "Package.swift").exists else { return }

        let executions = pluginExecutions
        let binaries = executions
            .flatMap(binaries)
            .reduce(into: [String: PluginBinary]()) { result, binary in
                result[binary.label] = binary
            }
            .values
            .sorted { $0.label < $1.label }

        try packagesRoot.mkpath()
        let group = CodeBuilder()
        group.call(
            Rules.Builtin.Call.filegroup(
                name: "plugins",
                srcs: .build { binaries.map { Starlark.Label.named($0.label) } },
                visibility: .public))
        /// The flags every trait is switched with, in the package the
        /// generator owns.
        buildTraitRules(group)
        try (packagesRoot + "BUILD").write(group.build())

        try writePluginPlan(executions)
        try (output + "plugin-host.swift").write(Self.pluginRunnerSource)
        let script = output + "plugins.sh"
        try script.write("""
        #!/bin/bash
        # Bazel supplies this host, its plan, every plugin and every tool.
        set -euo pipefail
        runfiles="${RUNFILES_DIR:-$0.runfiles}/_main"
        exec "$runfiles/_plugin_host" "$runfiles/plugin-plan.json" "$runfiles"

        """)

        /// `sh_binary` refuses a script that is not executable.
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: script.string)
    }

    private func writePluginPlan(_ executions: [PluginExecution]) throws {
        let plan = try executions.enumerated().map { index, execution in
            let workDirectory = pluginWorkDirectory(of: execution.target, in: execution.package)
            let request = try pluginRequest(for: execution, workDirectory: workDirectory)
            let payload = try JSONEncoder().encode(request)
            let firstForTarget = index == 0
                || executions[index - 1].package.directory != execution.package.directory
                || executions[index - 1].target.name != execution.target.name

            return [
                "package": execution.package.directory,
                "target": execution.target.name,
                "plugin": execution.usage.name,
                "executable": binary(
                    of: execution.plugin,
                    in: execution.pluginPackage).path,
                "output": workDirectory.absolute().string,
                "resetOutput": firstForTarget,
                "request": payload.base64EncodedString()
            ] as [String: Any]
        }
        var data = try JSONSerialization.data(
            withJSONObject: plan,
            options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        data.append(0x0A)
        try data.write(to: (output + "plugin-plan.json").url)
    }

    /// Bazel-native commands that describe the generated workspace.
    ///
    /// The answers are embedded in executable targets, so using them never
    /// depends on whichever `bazelize` executable happens to be on `PATH`.
    /// Bazel itself has no extension point for custom commands; `tools/bazel`
    /// keeps `bazel list config|trait|language` as aliases for the `bazel run`
    /// targets and forwards every other command unchanged.
    func writeListingCommands() throws {
        let directory = output + "tools"
        try directory.mkpath()

        let listings = [
            ("config", try Listing.config(output: output)),
            ("trait", Listing.traits(workspace: workspace)),
            ("language", Listing.languages(localizations)),
        ]
        let builder = CodeBuilder()
        builder.load(loadableRule: Rules.Shell.sh_binary)

        for (topic, contents) in listings {
            let name = "list-\(topic)"
            let script = directory + "\(name).sh"
            try script.write("""
            #!/bin/bash
            cat <<'BAZELIZE_LIST'
            \(contents)
            BAZELIZE_LIST

            """)
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o755],
                ofItemAtPath: script.string)
            builder.call(
                Rules.Shell.Call.sh_binary(
                    name: name,
                    srcs: ["\(name).sh"]))
        }

        try (directory + "BUILD").write(builder.build())

        try writeBazelWrapper(to: directory + "bazel")
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

        if [[ "${1:-}" == "list" ]]; then
            case "${2:-}" in
                config|trait|language)
                    exec "$BAZEL_REAL" run "//tools:list-${2}"
                    ;;
                *)
                    echo "Usage: bazel list config|trait|language" >&2
                    exit 2
                    ;;
            esac
        fi

        exec "$BAZEL_REAL" "$@"

        """)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: wrapper.string)
    }

    /// One plugin attached to one target.
    private struct PluginExecution {
        let package: SwiftPM.Package
        let target: SwiftPM.PackageTarget
        let usage: SwiftPM.PluginUsage
        let plugin: SwiftPM.PackageTarget
        let pluginPackage: SwiftPM.Package
    }

    /// Plugins of this package that a project-owned target actually uses.
    func usedPluginNames(in package: SwiftPM.Package) -> Set<String> {
        Set(pluginExecutions.lazy
            .filter { $0.pluginPackage.directory == package.directory }
            .map(\.plugin.name))
    }

    private var pluginExecutions: [PluginExecution] {
        workspace.packages
            .filter { $0.isRoot || $0.isLocal }
            .flatMap { package in
                package.manifest.targets.flatMap { target in
                    target.pluginUsages.compactMap { usage in
                        guard let (plugin, pluginPackage) = resolvedPlugin(usage, from: package) else {
                            return nil
                        }
                        return .init(
                            package: package,
                            target: target,
                            usage: usage,
                            plugin: plugin,
                            pluginPackage: pluginPackage)
                    }
                }
            }
    }

    private func resolvedPlugin(
        _ usage: SwiftPM.PluginUsage,
        from package: SwiftPM.Package) -> (SwiftPM.PackageTarget, SwiftPM.Package)?
    {
        let packages: [SwiftPM.Package]
        if let name = usage.package {
            let directory = workspace.directoryByIdentity[name.lowercased()]
            packages = workspace.packages.filter { $0.directory == directory }
        } else {
            packages = [package] + workspace.packages.filter { $0.directory != package.directory }
        }

        for candidate in packages {
            if let target = candidate.manifest.targets.first(where: {
                $0.name == usage.name && $0.type == "plugin"
            }) {
                return (target, candidate)
            }
        }
        return nil
    }

    private func binaries(_ execution: PluginExecution) -> [PluginBinary] {
        [binary(of: execution.plugin, in: execution.pluginPackage)]
            + execution.plugin.dependencies.compactMap { dependency in
                switch dependency.kind {
                case .target(let name), .byName(let name):
                    return toolBinary(named: name, in: execution.pluginPackage)
                case .product:
                    return nil
                }
            }
    }

    private func pluginRequest(
        for execution: PluginExecution,
        workDirectory: Path) throws -> SwiftPM.PluginWire.Request
    {
        var builder = SwiftPM.PluginContextBuilder(package: execution.package, generator: self)
        let targetId = try builder.add(package: execution.package, asking: execution.target)
        let workDirectoryId = builder.add(path: workDirectory.absolute().string)

        var tools: [String: SwiftPM.PluginWire.Tool] = [:]
        for dependency in execution.plugin.dependencies {
            let name: String
            switch dependency.kind {
            case .target(let value), .byName(let value):
                name = value
            case .product:
                continue
            }
            guard let binary = toolBinary(named: name, in: execution.pluginPackage) else { continue }
            tools[name] = .init(path: builder.add(path: "$RUNFILES/\(binary.path)"), triples: nil)
        }

        return .init(
            context: builder.context(workDirectoryId: workDirectoryId, tools: tools),
            rootPackageId: 0,
            targetId: targetId,
            pluginGeneratedSources: [],
            pluginGeneratedResources: [])
    }

    private func toolBinary(named name: String, in package: SwiftPM.Package) -> PluginBinary? {
        guard let target = package.manifest.targets.first(where: { $0.name == name }) else {
            return nil
        }
        if target.type == "executable" {
            return binary(of: target, in: package)
        }
        guard
            target.type == "binary",
            let artifact = artifact(of: target, in: package),
            case .artifactBundle = artifact.kind,
            Self.executable(inArtifactBundle: artifact.path) != nil
        else {
            return nil
        }
        return binary(of: target, in: package)
    }

    private func binary(
        of target: SwiftPM.PackageTarget,
        in package: SwiftPM.Package) -> PluginBinary
    {
        let rule = ruleName(of: target.name, in: package)
        let directory = "\(PluginSwiftPM.packagesDirectory)/\(package.directory)"

        return .init(
            label: "//\(directory):\(rule)",
            path: "\(directory)/\(rule)")
    }
}

extension SwiftPM.Generator {
    /// A program `//:plugins` has Bazel build before it runs.
    struct PluginBinary {
        let label: String
        /// Where it sits in the runner's runfiles.
        let path: String
    }
}
