//
//  Kit.swift
//
//
//  Created by Yume on 2022/4/29.
//

import PluginLoader
import Util
import XcodeProj
import Yams

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

    public final func run(_: Path) async throws {
        defer { tips() }

//        try await loadPlugins(mainfest)
        try generate()
        try await generateSwiftPackages()
    }

    public final func dump() throws {
        let encoder = YAMLEncoder()
        let yaml = try encoder.encode(project)
        print(yaml)
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
        let workspace = try await SwiftPM.loadWorkspace(
            output: outputRoot,
            root: project.packageRoot,
            locals: project.packages.local.map { local in
                project.workspaceRoot + local.relativePath
            })
        let deployment = await deployment()

        let generator = SwiftPM.Generator(
            output: outputRoot,
            workspace: workspace,
            deployment: deployment)
        try generator.generate()
        packageTips = generator.notes

        let count = workspace.packages.count
        Log.codeGenerate.info("Generate \(count, privacy: .public) Swift packages")
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
        try generateTargetBuild()
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

//        build.exportUncategorizedFiles(self)
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
        }

        try plugins.forEach { plugin in
            try plugin.generateFile(outputRoot)
        }
    }
}


// MARK: - clear
extension Kit {
    // MARK: Public

    public final func clear() {
        clearModule()
        clearBuild()
        clearConfig()
        clearPrebuiltBuild()
        clearTargetBuild()
        clearPluginExtraFile()
    }

    // MARK: Private

    /// {WORKSPACE}/MODULE.bazel
    private func clearModule() {
        try? module.clear()
    }

    /// {WORKSPACE}/BUILD
    private final func clearBuild() {
        try? build.clear()
    }

    /// {WORKSPACE}/config.bazelrc
    private final func clearConfig() {
        try? config.clear()
    }

    private final func clearPrebuiltBuild() {
        try? prebuilt.clear()
    }

    /// {WORKSPACE}/Target/BUILD
    private final func clearTargetBuild() {
        for build in targetsBuild {
            try? build.clear()
        }
    }

    private final func clearPluginExtraFile() {
        builtinPlugins.compactMap(\.custom).flatMap { $0 }.forEach { custom in
            let path = resolvedOutputPath(custom.path)
            try? path.delete()
        }
    }

    private func resolvedOutputPath(_ path: String) -> Path {
        let custom = Path(path)
        return custom.isAbsolute ? custom : outputRoot + custom
    }
}
