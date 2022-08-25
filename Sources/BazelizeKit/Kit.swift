//
//  Kit.swift
//
//
//  Created by Yume on 2022/4/29.
//

import Cocoapod
import CoreLocation
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

    public init(_ projPath: Path) async throws {
        project = try await Project(projPath)
        plugins = []
    }

    // MARK: Public

    public func run(_ mainfest: Path) async throws {
        defer { tip() }

        plugins = try await PluginLoader.load(manifest: mainfest, project)

        let targets = project.targets.compactMap {
            $0 as? XCode.Target
        }

        /// {WORKSPACE}/WORKSPACE
//        let spm_repositories = targets.spm_repositories(project.projectPath)
        let workspace = Workspace { builder in
            builder.default()
//            builder.custom(code: spm_repositories)
        }
        try? workspace.generate(project.workspacePath)

        /// {WORKSPACE}/BUILD
        try? project.generateBUILD(self)

        /// {WORKSPACE}/.bazelrc
        try? project.generateBazelRC(self)

        /// {WORKSPACE}/Target/BUILD
        for target in targets {
            try target.generateBUILD(self)
        }

        plugins.forEach { plugin in
            try? plugin.generateFile(project.workspacePath)
        }
    }

    public func dump() throws {
        let encoder = YAMLEncoder()
        let yaml = try encoder.encode(project)
        print(yaml)
    }

    // MARK: Internal

    let project: Project

    /// plugins...
    var plugins: [Plugin]
}

// MARK: - Plugins
extension Kit {
    private func tip() {
        plugins.forEach { plugin in
            plugin.tip()
        }
    }
}
