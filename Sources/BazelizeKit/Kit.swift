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
import Util
import XCode
import XcodeProj
import Yams

// MARK: - Kit

public final class Kit {
    // MARK: Lifecycle


    public init(_ projPath: Path) async throws {
        project = try await Project(projPath)
    }

    // MARK: Public


    public func run() async throws {
        defer { tip() }

        try await load()

        let targets = project.targets.compactMap {
            $0 as? XCode.Target
        }
        for target in targets {
            try target.generateBUILD(self)
        }

        let spm_repositories = targets.spm_repositories(project.projectPath)
        let workspace = Workspace { builder in
            builder.default()
            builder.custom(code: spm_repositories)
        }
        try? workspace.generate(project.workspacePath)

        try? pod?.generateFile(project.workspacePath)
    }

    public func dump() throws {
        let encoder = YAMLEncoder()
        let yaml = try encoder.encode(project)
        print(yaml)
    }

    // MARK: Internal

    let project: Project

    /// plugins...
    var pod: Pod?
}

// MARK: - Plugins
/// start -> load xcode
/// start -> load plugin list
/// load plugin list -> build plugin
/// build plugin -> load plugin
/// load xcode -> load plugin
extension Kit {
//    private func loadPluginList(_ path: Path?) async throws -> PluginList {}
//    private func buildPlugins(_ list: PluginList) async throws {}
//    private func loadPlugins(_ list: PluginList) async throws -> [Plugin] {}
//    private func load(_ path: Path?) async throws {
//        let list = try await loadPluginList(path)
//        try await buildPlugin(list)
//        self.plugins = try await loadPlugins(list)
//    }

    private func load() async throws {
        pod = try await Pod.parse(project.workspacePath)
    }

    private func tip() {
        pod?.tip()
    }
}
