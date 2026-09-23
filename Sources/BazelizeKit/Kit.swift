//
//  Kit.swift
//
//
//  Created by Yume on 2022/4/29.
//

import PluginLoader
import Util
import XcodeProj

// MARK: - Kit

public final class Kit {
    let project: Project
    let outputRoot: Path

    private lazy var roadmap = Bazel.Roadmap(output: outputRoot, project: project)
    lazy var version = Bazel.Version(outputRoot)
    lazy var module = Bazel.Module(outputRoot)
    lazy var build = Bazel.RootBuild(outputRoot)
    lazy var config = Bazel.BazelRC(outputRoot)
    lazy var rootRC = Bazel.RootRC(outputRoot)
    lazy var prebuilt = Bazel.PrebuiltBuild(outputRoot)
    lazy var targetsBuild = project.targets.map { target in
        Bazel.TargetBuild(outputRoot, target)
    }

    /// plugins...
    var plugins: [Plugin]

    private lazy var pluginSPM = PluginSwiftPM(self)

    lazy var builtinPlugins: [PluginBuiltin] = [
        PluginHttpArchive(self),
        PluginGitRepository(self),
        pluginSPM,
        PluginApple(self),
        PluginSwift(self),
        PluginXcodeProj(self),
        PluginPlistFragment(self),
        PluginLinker(self),
    ]

    // MARK: Lifecycle

    public init(_ projPath: Path, _ preferConfig: String?, outputPath: Path? = nil) async throws {
        project = try Project.load(path: projPath, preferConfig: preferConfig)
        outputRoot = outputPath ?? Path(project.workspacePath)
        plugins = []

        try await pluginSPM.loadPackageNames(projPath: projPath)
    }

    // MARK: Public

    /// Notes the run has for the user, collected while the package rules were
    /// generated.
    private var packageTips: [String] = []

    /// The generator that wrote the package rules, kept for the step that runs
    /// their build tool plugins once the workspace is complete.
    private var packageGenerator: SwiftPM.Generator?

    public final func run() async throws {
        defer { tips() }

        try generate()
        /// Which package a product belongs to is the resolved graph's answer,
        /// so the rules that name one are written once the packages have been
        /// resolved — everything those rules need besides that is already in
        /// the project.
        try await generateSwiftPackages()
        try generateTargetBuild()
        /// The workspace is complete here, which is what `//:plugins` needs to
        /// build the host, the plugins and their tools.
        try await runBuildToolPlugins()
    }
}

extension Kit {
//    private final func loadPlugins(_ mainfest: Path) async throws {
//        plugins = try await PluginLoader.load(manifest: mainfest, project)
//        for plugin in plugins {
//            Log.pluginLoader.info("Load Plugin \(plugin.name)(\(plugin.version))")
//        }
//    }

    private final func tips() {
        builtinPlugins.compactMap(\.tip).forEach { tip in
            print(tip)
        }

        if !packageTips.isEmpty {
            print("# Swift packages")
            packageTips.forEach { tip in
                print(tip)
            }
        }

        plugins.forEach { plugin in
            plugin.tip()
        }
    }
}

// MARK: - Swift packages
extension Kit {
    /// Rules for the packages the project depends on, generated from their
    /// manifests instead of by `rules_swift_package_manager`.
    private final func generateSwiftPackages() async throws {
        let locals = project.packages.local.map { local in
            project.workspaceRoot + local.relativePath
        }
        let deployment = await deployment()
        let workspace = try await SwiftPM.loadWorkspace(
            output: outputRoot,
            root: project.packageRoot,
            locals: locals,
            /// Which platforms the project builds decides whether a setting
            /// conditional on one applies at all.
            platforms: Set(deployment.project.keys))

        let generator = SwiftPM.Generator(
            output: outputRoot,
            workspace: workspace,
            deployment: deployment)
        try await generator.generate(locals: locals)
        packageGenerator = generator
        packageTips = generator.notes
        packageDirectoryByProduct(of: workspace)

        let count = workspace.packages.count
        Log.codeGenerate.info("Generate \(count, privacy: .public) Swift packages")
    }

    /// Runs the build tool plugins of the packages this project owns, the way
    /// the workspace runs them: `bazel run //:plugins`.
    ///
    /// A target compiles what its plugin generates, so a workspace whose
    /// plugins have never run is a workspace that does not build. Bazel builds
    /// the host, the plugins and their tools from the rules just written, so
    /// nothing here is a second implementation of running one — it is the
    /// first use of the only one.
    ///
    /// What landed decides how the rules name it, so the packages that have a
    /// plugin are written once more afterwards.
    private final func runBuildToolPlugins() async throws {
        guard let generator = packageGenerator, generator.hasBuildToolPlugins else { return }

        do {
            try await SwiftPM.PluginHost.runPlugins(in: outputRoot)
            try generator.refreshPluginPackages()
        } catch {
            generator.note("""
            `bazel run //:plugins` did not run the build tool plugins: \(error). \
            Whatever they generate is missing from the targets that use them.
            """)
        }

        packageTips = generator.notes
    }

    /// Which package directory declares each product, for the target rules
    /// that have to name one.
    ///
    /// A product name is the package's own, so two packages can ship one of
    /// the same name; such a name answers for neither, because nothing in an
    /// Xcode target says which package it meant.
    private final func packageDirectoryByProduct(of workspace: SwiftPM.Workspace) {
        var directories: [String: String] = [:]
        var ambiguous: Set<String> = []

        for package in workspace.packages {
            for product in package.manifest.products {
                if let existing = directories[product.name], existing != package.directory {
                    ambiguous.insert(product.name)
                    continue
                }
                directories[product.name] = package.directory
            }
        }

        for name in ambiguous {
            directories[name] = nil
        }

        pluginSPM.packageDirectoryByProduct = directories
    }

    /// The versions a package's targets end up compiled at: the lowest deployment
    /// target of the project's own targets, per platform, because that is the one
    /// a package has to be buildable against.
    ///
    /// A platform no target of the project builds for cannot fail, so it is left
    /// out. Where the project says nothing, the oldest version the installed SDK
    /// can build for stands in — the same answer SwiftPM reads out of the SDK.
    private final func deployment() async -> SwiftPM.Deployment {
        var floors: [String: String] = [:]
        var platforms: Set<String> = []

        for target in project.targets {
            if let platform = target.platformSDK.flatMap(SwiftPM.Deployment.platform(of:)) {
                platforms.insert(platform)
            }

            let declared: [(String, String?)] = [
                ("macos", target.prefer(\.platform.macOS)),
                ("ios", target.prefer(\.platform.iOS)),
                ("tvos", target.prefer(\.platform.tvOS)),
                ("watchos", target.prefer(\.platform.watchOS)),
            ]

            for (platform, version) in declared {
                guard let version, !version.isEmpty else { continue }
                guard let floor = floors[platform] else {
                    floors[platform] = version
                    continue
                }
                if SwiftPM.Deployment.isNewer(floor, than: version) {
                    floors[platform] = version
                }
            }
        }

        /// A platform the project builds for without saying which version: the
        /// oldest the installed SDK can build is what Xcode would use.
        for platform in platforms where floors[platform] == nil {
            floors[platform] = await SwiftPM.Deployment.sdkFloor(platform: platform)
        }

        return .init(project: floors)
    }
}

// MARK: - Generate
extension Kit {
    private final func generate() throws {
        try generateRoadmap()
        try generateVersion()
        try generateModule()
        try generateBuild()
        try generateConfig()
        try generatePrebuiltBuild()
        try generatePluginExtraFile()
    }

    private func generateRoadmap() throws {
        try roadmap.prepare()
    }

    private func generateVersion() throws {
        try version.path.write(version.code)
    }

    /// {WORKSPACE}/MODULE.bazel
    private func generateModule() throws {
        for plugin in builtinPlugins {
            plugin.module(module.builder)
        }
        try module.write()

        let path = module.path
        Log.codeGenerate.info("Create `Workspace` at \(path, privacy: .public)")
    }

    /// {WORKSPACE}/BUILD
    private final func generateBuild() throws {
        build.setup(config: project.config)
        for plugin in builtinPlugins {
            plugin.build(build.builder)
        }
        try build.write()

        let path = build.path
        Log.codeGenerate.info("Create `BUILD` at \(path, privacy: .public)")
    }

    /// {WORKSPACE}/config.bazelrc and {WORKSPACE}/.bazelrc
    private final func generateConfig() throws {
        config.setup(config: project.config, targets: project.targets)
        try config.write()
        try rootRC.ensureImport()

        let path = config.path
        Log.codeGenerate.info("Create `config.bazelrc` at \(path, privacy: .public)")
    }

    private final func generatePrebuiltBuild() throws {
        prebuilt.setup(self)
        try prebuilt.path.parent().mkpath()
        try prebuilt.write()

        let path = prebuilt.path
        Log.codeGenerate.info("Create `Prebuilt/BUILD` at \(path, privacy: .public)")
    }


    /// {WORKSPACE}/Target/BUILD
    private final func generateTargetBuild() throws {
        for build in targetsBuild {
            var build = build

            try build.mkpath()
            build.setup(self)
            try build.write()

            let path = build.path
            Log.codeGenerate.info("Create BUILD at \(path, privacy: .public)")
        }
    }

    private final func generatePluginExtraFile() throws {
        try builtinPlugins.compactMap(\.custom).flatMap { $0 }.forEach { custom in
            let path = resolvedOutputPath(custom.path)
            try path.parent().mkpath()
            try path.write(custom.content)

            /// A script is written to be run: `sh_binary` refuses one that is
            /// not executable.
            if path.extension == "sh" {
                try FileManager.default.setAttributes(
                    [.posixPermissions: 0o755],
                    ofItemAtPath: path.string)
            }
        }

        try plugins.forEach { plugin in
            try plugin.generateFile(outputRoot)
        }
    }

    private func resolvedOutputPath(_ path: String) -> Path {
        let custom = Path(path)
        return custom.isAbsolute ? custom : outputRoot + custom
    }
}

