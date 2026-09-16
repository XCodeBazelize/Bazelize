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
    let spm: SwiftPM.Mode

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
        PluginXCodeProj(self),
        PluginPlistFragment(self),
        PluginLinker(self),
    ]

    // MARK: Lifecycle

    public init(
        _ projPath: Path,
        _ preferConfig: String?,
        outputPath: Path? = nil,
        spm: SwiftPM.Mode = .rspm) async throws
    {
        project = try Project.load(path: projPath, preferConfig: preferConfig)
        outputRoot = outputPath ?? Path(project.workspacePath)
        self.spm = spm
        plugins = []

        try await pluginSPM.loadPackageNames(projPath: projPath)
    }

    // MARK: Public

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
        guard spm == .native else { return }

        let workspace = try await SwiftPM.loadWorkspace(output: outputRoot)
        try SwiftPM.Generator(output: outputRoot, workspace: workspace).generate()

        let count = workspace.packages.count
        Log.codeGenerate.info("Generate \(count, privacy: .public) Swift packages")
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
