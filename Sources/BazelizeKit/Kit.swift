//
//  Kit.swift
//
//
//  Created by Yume on 2022/4/29.
//

import Foundation
import PathKit
import PluginInterface
import PluginLoader
import Util
import XCode
import XcodeProj
import Yams

// MARK: - Kit

public final class Kit {
    // MARK: Lifecycle

    public init(_ projPath: Path, _ preferConfig: String?) async throws {
        project = try await Project(projPath, preferConfig)
        plugins = []
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

    // MARK: Internal

    lazy var workspace = Workspace(project.workspacePath) { builder in
        builder.default()
        builder.rulesPlistFragment()
    }

    lazy var config = BazelRC(project.workspacePath)
    lazy var build = Build(project.workspacePath)
    lazy var targetsBuild = project.targets.compactMap {
        $0 as? XCode.Target
    }.map { target in
        TargetBuild(project.workspacePath, target)
    }

    let project: Project

    /// plugins...
    var plugins: [Plugin]
}


extension Kit {
    private final func loadPlugins(_ mainfest: Path) async throws {
        plugins = try await PluginLoader.load(manifest: mainfest, project)
        for plugin in plugins {
            Log.pluginLoader.info("Load Plugin \(plugin.name)(\(plugin.version))")
        }
    }

    private final func tips() {
        plugins.forEach { plugin in
            plugin.tip()
        }
    }
}

// MARK: - Generate
extension Kit {
    private final func generate() {
        generateWorkspace()
        generateBuild()
        generateConfig()
        generateTargetBuild()
        generatePluginExtraFile()
    }

    /// {WORKSPACE}/WORKSPACE
    private final func generateWorkspace() {
        try? workspace.write()


        let path = workspace.path
        Log.codeGenerate.info("Create `Workspace` at \(path, privacy: .public)")
    }

    /// {WORKSPACE}/BUILD
    private final func generateBuild() {
        build.setup(config: project.config)
        build.exportUncategorizedFiles(self)
        build.build()
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
        plugins.forEach { plugin in
            try? plugin.generateFile(project.workspacePath)
        }
    }
}


// MARK: - clear
extension Kit {
    // MARK: Public

    public final func clear() {
        clearWorkspace()
        clearBuild()
        clearConfig()
        clearTargetBuild()
        clearPluginExtraFile()
    }

    // MARK: Private

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

    private final func clearPluginExtraFile() { }
}
