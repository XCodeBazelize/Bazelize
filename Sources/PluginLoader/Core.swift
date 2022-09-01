//
//  Core.swift
//
//
//  Created by Yume on 2022/8/24.
//

import Foundation
import PathKit
import PluginInterface
import Util

/// start -> load xcode
/// start -> load plugin list
/// load plugin list -> build plugin
/// build plugin -> load plugin
/// load xcode -> load plugin
public func load(manifest: Path, _ proj: XCodeProject) async throws -> [Plugin] {
    guard manifest.exists else {
        return []
    }

    print("Parse Manifest: \(manifest.string)")
    let infos = try parseManifest(manifest)

    print("Build Plugins")
    let buildPlugins = try PluginBuilder.build(plugins: infos)

    print("Load Plugins")
    let result = try await withThrowingTaskGroup(of: Plugin?.self) { group -> [Plugin?] in
        let build = Path.home + ".bazelize" + "build" + swift
        for plugin in buildPlugins {
            for lib in plugin.libsName {
                group.addTask {
                    let path = (build + plugin.user_repo + lib).string
                    return try await PluginLoader.load(at: path, proj: proj)
                }
            }
        }

        return try await group.all
    }
    return result.compactMap { $0 }
}
