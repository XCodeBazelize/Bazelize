//
//  SwiftPM+PluginHost.swift
//
//
//  Running a package's build tool plugins.
//

import Foundation
@preconcurrency import PathKit
import Subprocess
import System
import Util

extension SwiftPM {
    /// Runs the build tool plugins of an already generated workspace.
    ///
    /// Nothing else is generated: the rules are already there and do not change
    /// when a plugin writes a different set of files, because they glob the
    /// directory the plugin writes into. What comes back is what to tell the
    /// user about.
    /// `plugins` and `tools` are what Bazel built, by target name: a plugin is
    /// a program and so is the tool it runs, and building them is Bazel's job
    /// wherever `//:plugins` is what started this.
    public static func runPlugins(
        output: Path,
        locals: [Path],
        plugins: [String: Path] = [:],
        tools: [String: Path] = [:]) async throws -> [String]
    {
        let workspace = try await loadWorkspace(output: output, root: nil, locals: locals)
        let generator = Generator(
            output: output,
            workspace: workspace,
            deployment: .init(project: [:]),
            built: .init(plugins: plugins, tools: tools))

        return await generator.runPlugins().notes
    }
}

extension SwiftPM.Generator {
    /// Runs the build tool plugins of the packages this project owns, into the
    /// directory their output belongs in.
    ///
    /// bazelize is the plugin host here: it compiles the plugin, hands it the
    /// package graph and a directory to write into, and runs the commands it
    /// asks for. What the plugin writes and what it calls those files is the
    /// plugin's business — the host supplies the place, and is told afterwards
    /// what landed there.
    ///
    /// Asking SwiftPM instead means building the whole target the plugin is
    /// attached to, which fails for reasons that have nothing to do with the
    /// plugin, and which on some toolchains silently does not run the plugin at
    /// all for a C-family target.
    func runPlugins() async -> SwiftPM.PluginOutputs {
        var outputs: [String: SwiftPM.PluginOutputs.Output] = [:]
        var notes: [String] = []

        for package in workspace.packages where package.isRoot || package.isLocal {
            for target in package.manifest.targets where !target.pluginUsages.isEmpty {
                let directory = pluginWorkDirectory(of: target, in: package)
                try? directory.delete()

                var produced = false
                for usage in target.pluginUsages {
                    do {
                        produced = try await run(
                            plugin: usage,
                            on: target,
                            in: package,
                            at: directory) || produced
                    } catch {
                        notes.append(note(usage, target, package, "\(error)"))
                    }
                }

                guard produced, directory.isDirectory else { continue }
                outputs["\(package.directory)/\(target.name)"] = .init(
                    root: directory,
                    files: Self.walk(directory).sorted())
            }
        }

        return .init(outputs: outputs, notes: notes)
    }

    /// Where a target's plugins write: beside the rules of the package that
    /// declares it, which is where every other generated file of that package
    /// already is.
    func pluginWorkDirectory(of target: SwiftPM.PackageTarget, in package: SwiftPM.Package) -> Path {
        output + PluginSwiftPM.packagesDirectory + package.directory + "Generated/\(target.name)Plugin"
    }

    // MARK: Private

    private func note(
        _ usage: SwiftPM.PluginUsage,
        _ target: SwiftPM.PackageTarget,
        _ package: SwiftPM.Package,
        _ reason: String) -> String
    {
        let message = """
        \(package.directory)/\(target.name) did not run the \(usage.name) plugin: \(reason). \
        Whatever that plugin generates is missing from the target.
        """
        Log.codeGenerate.warning("\(message, privacy: .public)")
        return message
    }

    /// Asks one plugin what to run, and runs it. `true` when it asked for
    /// anything at all.
    private func run(
        plugin usage: SwiftPM.PluginUsage,
        on target: SwiftPM.PackageTarget,
        in package: SwiftPM.Package,
        at directory: Path) async throws -> Bool
    {
        guard let (pluginTarget, pluginPackage) = self.plugin(usage, from: package) else {
            throw SwiftPM.PluginError.undecodable("no target named \(usage.name) declares it")
        }

        let executable = try await compile(plugin: pluginTarget, in: pluginPackage)
        try directory.mkpath()

        let context = try await self.context(
            for: target,
            in: package,
            plugin: pluginTarget,
            pluginPackage: pluginPackage,
            workDirectory: directory)

        let commands = try await SwiftPM.PluginHost.ask(executable: executable, request: context)
        guard !commands.isEmpty else { return false }

        for command in commands {
            try await SwiftPM.PluginHost.run(command)
        }

        return true
    }

    /// The target that implements a plugin, and the package it belongs to: a
    /// usage names the plugin, and optionally the package it comes from.
    private func plugin(
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

    /// Compiles a plugin into a program the host can talk to.
    ///
    /// A plugin target depends on nothing but the toolchain's `PackagePlugin`,
    /// so compiling it needs no package graph — which is the whole reason the
    /// host can run one without building anything else.
    private func compile(plugin target: SwiftPM.PackageTarget, in package: SwiftPM.Package) async throws -> Path {
        /// Bazel built it: `//:plugins` has the plugin as `data`, so it is in
        /// the runfiles by the time the host runs.
        if let prebuilt = built.plugins[target.name], prebuilt.exists { return prebuilt }

        let built = output + ".bazelize/plugins" + package.directory + target.name
        if built.exists { return built }

        guard let directory = sourceDirectory(of: target, in: package) else {
            throw SwiftPM.PluginError.compileFailed("no source directory")
        }

        let sources = Self.walk(directory).filter { $0.extension == "swift" }.map(\.string)
        guard !sources.isEmpty else {
            throw SwiftPM.PluginError.compileFailed("no sources")
        }

        try built.parent().mkpath()
        try await SwiftPM.PluginHost.compile(
            sources: sources,
            module: target.name,
            toolsVersion: package.manifest.toolsVersion,
            to: built)

        return built
    }

    /// The graph the plugin is given, and the tools it may run.
    private func context(
        for target: SwiftPM.PackageTarget,
        in package: SwiftPM.Package,
        plugin: SwiftPM.PackageTarget,
        pluginPackage: SwiftPM.Package,
        workDirectory: Path) async throws -> SwiftPM.PluginWire.Request
    {
        var builder = SwiftPM.PluginContextBuilder(package: package, generator: self)
        let targetId = try builder.add(package: package, asking: target)
        let workDirId = builder.add(path: workDirectory.absolute().string)

        var tools: [String: SwiftPM.PluginWire.Tool] = [:]
        for dependency in plugin.dependencies {
            guard case .target(let name) = dependency.kind else {
                guard case .byName(let name) = dependency.kind else { continue }
                if let tool = try await self.tool(named: name, in: pluginPackage) {
                    tools[name] = .init(path: builder.add(path: tool.string), triples: nil)
                }
                continue
            }

            if let tool = try await self.tool(named: name, in: pluginPackage) {
                tools[name] = .init(path: builder.add(path: tool.string), triples: nil)
            }
        }

        return .init(
            context: builder.context(workDirectoryId: workDirId, tools: tools),
            rootPackageId: 0,
            targetId: targetId,
            pluginGeneratedSources: [],
            pluginGeneratedResources: [])
    }

    /// The program a plugin runs, built by SwiftPM because it is an ordinary
    /// executable target with ordinary dependencies.
    ///
    /// Only this one product is built, rather than the target the plugin is
    /// attached to: which product holds the tool is read from the manifest here
    /// instead of guessed from the target's name, which is what some toolchains
    /// get wrong.
    private func tool(named name: String, in package: SwiftPM.Package) async throws -> Path? {
        guard package.manifest.targets.contains(where: { $0.name == name && $0.type == "executable" })
        else {
            return nil
        }

        /// Bazel built it, so SwiftPM never has to load the package the tool
        /// lives in — which some toolchains cannot do when a plugin names its
        /// tool by target.
        if let prebuilt = built.tools[name], prebuilt.exists { return prebuilt }

        let product = package.manifest.products.first { product in
            product.targets.contains(name)
        }?.name ?? name

        return try await SwiftPM.PluginHost.build(product: product, of: package.root)
    }
}
