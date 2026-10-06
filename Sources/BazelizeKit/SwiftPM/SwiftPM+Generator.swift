//
//  SwiftPM+Generator.swift
//
//
//  Bazel rules for the Swift packages a project depends on.
//

import BazelRules
import Foundation
@preconcurrency import PathKit
import Starlark
import Util

extension SwiftPM {
    /// Writes one `BUILD` per package under `Packages/`, plus the source tree it
    /// points at.
    ///
    /// The layout matches what `Targets/` already does: a symlink tree of the
    /// sources and a generated `BUILD` beside it. Nothing outside `Packages/`
    /// changes — a target reaches a product through the facade either way.
    final class Generator {
        let output: Path
        let workspace: Workspace

        let deployment: Deployment

        /// The packages whose targets use a build tool plugin, which are written
        /// again once `bazel run //:plugins` has produced what those plugins
        /// generate.
        private var pluginPackages: [String] = []

        var kinds: [String: [String: TargetKind]] = [:]

        /// The `config_setting_group` a condition on several traits asked for,
        /// by name, written with the flags once every rule is generated.
        var traitGroups: [String: [String]] = [:]

        /// Platform alternatives a condition names, emitted as one group so a
        /// setting or dependency applies when any named platform is built.
        var platformGroups: [String: [String]] = [:]

        /// Platform names with no Bazel constraint. Their conditions use a
        /// generated constraint no real target platform carries, so they stay
        /// false rather than becoming unconditional.
        var unsupportedPlatforms: Set<String> = []

        /// Conditions that require both a trait expression and a build
        /// configuration, emitted after every package has registered its use.
        var conditionGroups: [String: [String]] = [:]

        /// SwiftPM build configurations used by conditional settings.
        var configurationConditions: Set<String> = []

        /// What a consumer calls another package's module: the aliases asked
        /// for, by the package that owns the module and the target inside it.
        /// Collected before anything is written, because the rule that carries
        /// an alias belongs to the package being aliased.
        var moduleAliases: [String: [String: Set<String>]] = [:]

        /// What a caller tells the user about: where the build differs from what
        /// the package asked for, and why.
        private(set) var notes: [String] = []

        /// Something a caller has to be told: it is logged where a run is
        /// watched, and carried back for the report at the end of one.
        func note(_ message: String) {
            Log.codeGenerate.warning("\(message, privacy: .public)")
            notes.append(message)
        }

        init(output: Path, workspace: Workspace, deployment: Deployment) {
            self.output = output
            self.workspace = workspace
            self.deployment = deployment
        }

        func generate(locals: [Path] = []) async throws {
            for package in workspace.packages {
                kinds[package.directory] = try supportedTargets(of: package)
                report(deploymentOf: package)
                report(pluginsOf: package)
            }

            collectModuleAliases()

            pluginPackages = workspace.packages
                .filter { package in
                    (package.isRoot || package.isLocal)
                        && package.manifest.targets.contains { !$0.pluginUsages.isEmpty }
                }
                .map(\.directory)

            try preparePackagesRoot()

            for package in workspace.packages {
                try generate(package)
            }

            try writePluginRunner()
            /// Written whether or not there is a trait to switch: the root
            /// `.bazelrc` imports it, and an import of a file that is not
            /// there is a workspace that does not load.
            try writeTraitConfigs()
            try writeLanguageConfigs()
            try writeListingCommands()
        }

        /// Whether anything is there for `bazel run //:plugins` to run.
        var hasBuildToolPlugins: Bool {
            !pluginPackages.isEmpty
        }

        /// Writes the rules of the packages whose plugins have now run.
        ///
        /// What a plugin writes is the plugin's business: the rules name the
        /// directory and the kinds of file in it, and a kind that is neither a
        /// source nor a header of the target — a resource, or a file with no
        /// extension at all — is only known from what landed there. The rules
        /// are written once more with that in hand, so the first run of a
        /// workspace says the same thing every later one does.
        func refreshPluginPackages() throws {
            for package in workspace.packages where pluginPackages.contains(package.directory) {
                try generate(package)
            }
        }

        /// A package that declares a platform version the project does not reach is
        /// compiled at the project's version anyway, and fails in whichever newer
        /// API it uses. The reason is in the manifest, not in that error, so it is
        /// said out loud.
        private func report(deploymentOf package: Package) {
            for unmet in deployment.unmet(package) {
                let message = """
                \(package.directory) declares \(unmet.platform) \(unmet.required), \
                and the project builds \(unmet.platform) \(unmet.project): \
                the package is compiled at \(unmet.project) and may not support it.
                """

                Log.codeGenerate.warning("\(message, privacy: .public)")
                notes.append(message)
            }
        }

        /// A dependency's build tool plugin is not run.
        ///
        /// `//:plugins` runs the plugins of the packages in the project's own
        /// repository; a dependency's are left alone, because a dependency is
        /// built as it was resolved. Every plugin in the corpus is a linter,
        /// which produces no source: a build without it is the same build. One
        /// that generates source would leave a target missing the files it
        /// expects, and that compile error says nothing about a plugin, so the
        /// plugin is named here instead.
        private func report(pluginsOf package: Package) {
            guard !package.isRoot, !package.isLocal else {
                reportForeignPlugins(of: package)
                return
            }

            let used = package.manifest.targets
                .filter { $0.type != "test" }
                .flatMap(\.pluginUsages)
                .map(\.name)

            for plugin in Set(used).sorted() {
                let message = """
                \(package.directory) asks for the \(plugin) plugin, which is not run: \
                a linter changes nothing, a plugin that generates source does.
                """

                Log.codeGenerate.warning("\(message, privacy: .public)")
                notes.append(message)
            }
        }

        /// A plugin a generated package asks for and another package owns.
        ///
        /// Rules are written for the packages of the project's own repository,
        /// so a plugin living anywhere else has no target to build and is not
        /// run — naming it in `//:plugins` would leave that target unloadable
        /// and stop every other plugin with it.
        private func reportForeignPlugins(of package: Package) {
            let foreign = package.manifest.targets
                .filter { $0.type != "test" }
                .flatMap(\.pluginUsages)
                .filter { usage in
                    guard let owner = pluginOwner(of: usage, from: package) else { return false }
                    return !owner.isRoot && !owner.isLocal
                }
                .map(\.name)

            for plugin in Set(foreign).sorted() {
                let message = """
                \(package.directory) asks for the \(plugin) plugin, which another \
                package owns and this workspace does not build: it is not run.
                """

                Log.codeGenerate.warning("\(message, privacy: .public)")
                notes.append(message)
            }
        }

        // MARK: Private

        var packagesRoot: Path {
            output + PluginSwiftPM.packagesDirectory
        }

        /// `Packages/` is generated output. Rebuilding it removes rules for a
        /// dependency or target that left the graph; a stale `BUILD` would
        /// otherwise remain part of `//...`. The output root itself stays:
        /// SwiftPM and Bazel keep their resolved state beside this directory.
        private func preparePackagesRoot() throws {
            if packagesRoot.exists { try packagesRoot.delete() }
            try packagesRoot.mkpath()
            try (packagesRoot + "swiftpm_resource_bundle.bzl").write(Self.resourceBundleRule)
        }

        private func generate(_ package: Package) throws {
            let root = packagesRoot + package.directory
            try root.mkpath()

            let builder = CodeBuilder()
            var emitted = kinds[package.directory] ?? [:]

            /// A plugin of a package this project owns is built by Bazel, so
            /// `//:plugins` can run it without SwiftPM having to load — let
            /// alone build — the package it lives in. A command plugin is built
            /// too, with the target that runs it: nothing builds it, someone
            /// asks for it.
            if package.isRoot || package.isLocal {
                let used = usedPluginNames(in: package)
                for target in package.manifest.targets where target.type == "plugin" {
                    guard let prefix = try materialize(target, in: package, at: root) else { continue }

                    if target.pluginCapability?.isCommand == true {
                        try buildCommandPlugin(target, in: package, prefix: prefix, root: root, builder: builder)
                    } else if used.contains(target.name) {
                        buildPlugin(target, in: package, prefix: prefix, builder: builder)
                    }
                }
            }

            for target in package.manifest.targets {
                guard let kind = emitted[target.name] else { continue }

                if case .binary = kind {
                    if try !buildBinary(target, in: package, root: root, builder: builder) {
                        emitted[target.name] = nil
                    }
                    continue
                }

                guard let prefix = try materialize(target, in: package, at: root) else { continue }

                if case .system = kind {
                    if !buildSystemLibrary(
                        target,
                        in: package,
                        prefix: prefix,
                        root: root,
                        builder: builder)
                    {
                        emitted[target.name] = nil
                    }
                    continue
                }

                let generated = try materialize(
                    pluginOutputsOf: target,
                    in: package,
                    at: root,
                    kind: kind)

                let resources = try buildResources(
                    target,
                    in: package,
                    prefix: prefix,
                    root: root,
                    kind: kind,
                    generated: generated.resources,
                    builder: builder)

                switch kind {
                case .macro:
                    buildMacro(
                        target,
                        in: package,
                        prefix: prefix,
                        generated: generated.sources,
                        builder: builder)
                case .executable:
                    buildExecutable(
                        target,
                        in: package,
                        prefix: prefix,
                        generated: generated.sources,
                        resources: resources,
                        builder: builder)
                case .test:
                    buildTest(
                        target,
                        in: package,
                        prefix: prefix,
                        generated: generated.sources,
                        resources: resources,
                        builder: builder)
                case .swift:
                    build(
                        target,
                        in: package,
                        prefix: prefix,
                        generated: generated.sources,
                        resources: resources,
                        builder: builder)
                case .clang:
                    buildClang(
                        target,
                        in: package,
                        prefix: prefix,
                        root: root,
                        generated: generated,
                        resources: resources,
                        builder: builder)
                case .binary, .system, .unsupported:
                    continue
                }
            }
            try buildSnippets(
                in: package,
                root: root,
                emitted: emitted,
                builder: builder)


            for product in package.manifest.products {
                build(product, emitted: Set(emitted.keys), package: package, builder: builder)
            }

            try (root + "BUILD").write(builder.build())
        }
    }
}
