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

    public init(_ projPath: Path, _ preferConfig: String? = nil) async throws {
        project = try await Project(projPath, preferConfig)
        plugins = []
    }

    // MARK: Public

    public final func run(_ mainfest: Path) async throws {
        defer { tips() }

        try await loadPlugins(mainfest)

        generateWorkspace()
        generateBuild()
        generateBazelRC()
        generateTargetBuild()
        generatePluginExtraFile()
    }

    public final func dump() throws {
        let encoder = YAMLEncoder()
        let yaml = try encoder.encode(project)
        print(yaml)
    }

    // MARK: Internal

    let project: Project

    /// plugins...
    var plugins: [Plugin]
}


extension Kit {
    private final func loadPlugins(_ mainfest: Path) async throws {
        plugins = try await PluginLoader.load(manifest: mainfest, project)
        for plugin in plugins {
            print("Load Plugin \(plugin.name)(\(plugin.version))")
        }
    }

    private final func tips() {
        plugins.forEach { plugin in
            plugin.tip()
        }
    }

    private final func generatePluginExtraFile() {
        plugins.forEach { plugin in
            try? plugin.generateFile(project.workspacePath)
        }
    }
}

extension Kit {
    /// {WORKSPACE}/WORKSPACE
    private final func generateWorkspace() {
        let workspace = Workspace { builder in
            builder.default()
        }
        try? workspace.generate(project.workspacePath)
    }

    /// {WORKSPACE}/BUILD
    private final func generateBuild() {
        try? project.generateBUILD(self)
    }

    /// {WORKSPACE}/.bazelrc
    private final func generateBazelRC() {
        try? project.generateBazelRC(self)
    }


    /// {WORKSPACE}/Target/BUILD
    private final func generateTargetBuild() {
        let targets = project.targets.compactMap {
            $0 as? XCode.Target
        }

        for target in targets {
            try? target.generateBUILD(self)
        }
    }
}
