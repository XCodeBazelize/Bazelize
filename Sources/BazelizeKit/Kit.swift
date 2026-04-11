//
//  Kit.swift
//
//
//  Created by Yume on 2022/4/29.
//

import Foundation
import PathKit
import PluginLoader
import Util
import XCode
import XcodeProj
import Yams

// MARK: - Kit

public final class Kit {
    let project: Project

    lazy var module = Bazel.Module(project.workspacePath)
    lazy var workspace = Bazel.Workspace(project.workspacePath)
    lazy var build = Bazel.RootBuild(project.workspacePath)
    lazy var config = Bazel.BazelRC(project.workspacePath)
    lazy var targetsBuild = project.targets.map { target in
        Bazel.TargetBuild(project.workspacePath, target)
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
        PluginImported(self),
    ]

    // MARK: Lifecycle

    public init(_ projPath: Path, _ preferConfig: String?) async throws {
        project = try await Project(projPath, preferConfig)
        plugins = []
        
        try await pluginSPM.loadPackageNames(projPath: projPath)
    }

    // MARK: Public

    public final func run(_ mainfest: Path) async throws {
        defer { tips() }

        try await loadPlugins(mainfest)

        generate()
    }

    public final func dump() throws {
        let encoder = YAMLEncoder()
        let yaml = try encoder.encode(project)
        print(yaml)
    }
}


extension Kit {
    private final func loadPlugins(_ mainfest: Path) async throws {
        plugins = try await PluginLoader.load(manifest: mainfest, project)
        for plugin in plugins {
            Log.pluginLoader.info("Load Plugin \(plugin.name)(\(plugin.version))")
        }
    }

    private final func tips() {
        builtinPlugins.compactMap(\.tip).forEach { tip in
            print(tip)
        }

        plugins.forEach { plugin in
            plugin.tip()
        }
    }
}

// MARK: - Generate
extension Kit {
    private final func generate() {
        generateModule()
        generateWorkspace()
        generateBuild()
        generateConfig()
        generateTargetBuild()
        generatePluginExtraFile()
    }

    /// {WORKSPACE}/MODULE.bazel
    private func generateModule() {
        for plugin in builtinPlugins {
            plugin.module(module.builder)
        }
        try? module.write()

        let path = module.path
        Log.codeGenerate.info("Create `Workspace` at \(path, privacy: .public)")
    }

    /// {WORKSPACE}/WORKSPACE
    private final func generateWorkspace() {
//        for plugin in builtinPlugins {
//            plugin.workspace(workspace.builder)
//        }
//        try? workspace.write()
//
//        let path = workspace.path
//        Log.codeGenerate.info("Create `Workspace` at \(path, privacy: .public)")
    }

    /// {WORKSPACE}/BUILD
    private final func generateBuild() {
        build.setup(config: project.config)
        build.exportUncategorizedFiles(self)
        for plugin in builtinPlugins {
            plugin.build(build.builder)
        }
        try? build.write()

        let path = build.path
        Log.codeGenerate.info("Create `BUILD` at \(path, privacy: .public)")
    }

    /// {WORKSPACE}/config.bazelrc
    private final func generateConfig() {
        config.setup(config: project.config)
        try? config.write()

        let path = config.path
        Log.codeGenerate.info("Create `config.bazelrc` at \(path, privacy: .public)")
    }


    /// {WORKSPACE}/Target/BUILD
    private final func generateTargetBuild() {
        for build in targetsBuild {
            var build = build

            try? build.mkpath()
            build.setup(self)
            try? build.write()

            let path = build.path
            Log.codeGenerate.info("Create BUILD at \(path, privacy: .public)")
        }
    }

    private final func generatePluginExtraFile() {
        builtinPlugins.compactMap(\.custom).flatMap { $0 }.forEach { custom in
            let path = Path(custom.path)
            try? path.parent().mkpath()
            try? path.write(custom.content)
        }

        plugins.forEach { plugin in
            try? plugin.generateFile(project.workspacePath)
        }
    }
}


// MARK: - clear
extension Kit {
    // MARK: Public

    public final func clear() {
        clearModule()
        clearWorkspace()
        clearBuild()
        clearConfig()
        clearTargetBuild()
        clearPluginExtraFile()
    }

    // MARK: Private

    /// {WORKSPACE}/MODULE.bazel
    private func clearModule() {
        try? module.clear()
    }

    /// {WORKSPACE}/WORKSPACE
    private final func clearWorkspace() {
        try? workspace.clear()
    }

    /// {WORKSPACE}/BUILD
    private final func clearBuild() {
        try? build.clear()
    }

    /// {WORKSPACE}/config.bazelrc
    private final func clearConfig() {
        try? config.clear()
    }

    /// {WORKSPACE}/Target/BUILD
    private final func clearTargetBuild() {
        for build in targetsBuild {
            try? build.clear()
        }
    }

    private final func clearPluginExtraFile() {
        builtinPlugins.compactMap(\.custom).flatMap { $0 }.forEach { custom in
            let path = Path(custom.path)
            try? path.delete()
        }
    }
}
