//
//  PluginBuilder.swift
//
//
//  Created by Yume on 2022/8/24.
//

import Foundation
import PathKit
import SwiftCommand
import SystemPackage
import Util

// MARK: - PluginBuilder

/// ~/.bazelize
///     git/XCodeBazelize_Bazelize
///     build/5.6/XCodeBazelize_Bazelize/1.0.0
enum PluginBuilder {
    // MARK: Internal

    static func build(plugins: [PluginInfo]) throws -> [PluginInfo] {
        try git.mkpath()
        try build.mkpath()

        return plugins.compactMap { info -> PluginInfo? in
            if checkExist(plugin: info) {
                return info
            }
            do {
                try build(plugin: info)
                return info
            } catch {
                Log.pluginLoader.warning("Build Plugin(\(info.repo)) Fail: \(error.localizedDescription)")
                return nil
            }
        }
    }

    // MARK: Private

    private static let root = Path.home + ".bazelize"
    private static let git = root + "git"
    private static let build = root + "build" + swift

    private static let commandGit = Command.findInPath(withName: "git")
    private static let commandSwift = Command.findInPath(withName: "swift")


    private static func checkExist(plugin: PluginInfo) -> Bool {
        plugin.paths
            .map { (path: String) -> Path in
                build + path
            }
            .map(\.exists)
            .reduce(true) { partialResult, next in
                partialResult && next
            }
    }

    /// cd ~/.bazelize/git
    /// test XCodeBazelize_Bazelize
    ///     false
    ///         git clone XCodeBazelize/Bazelize.git XCodeBazelize_Bazelize
    /// cd XCodeBazelize_Bazelize
    ///
    ///  git pull?
    ///  git fetch --all --tags?
    ///
    /// git checkout tag
    /// swift build -c release
    /// cp .build/release/*.dylib build/XCodeBazelize_Bazelize/tag
    private static func build(plugin: PluginInfo) throws {
        let repo = git + plugin.user_repo
        if !repo.exists {
            _ = try commandGit?.setCWD(FilePath(git.string))
                .addArguments("clone", plugin.url, plugin.user_repo)
                .setStdout(.null)
                .logging()
                .wait()
        }

        _ = try commandGit?.setCWD(FilePath(repo.string))
            .addArguments("checkout", plugin.tag)
            .setStdout(.null)
            .logging()
            .wait()

        _ = try commandSwift?.setCWD(FilePath(repo.string))
            .addArguments("build", "-c", "release")
            .setStdout(.null)
            .logging()
            .wait()

        let release = repo + ".build" + "release"

        try plugin.libsName.forEach { lib in
            let from = release + lib
            let toDir = build + plugin.user_repo
            try toDir.mkpath()
            let to = toDir + lib
            Log.pluginLoader.info("cp \(from.string) \(to.string)")
            try from.copy(to)
        }
    }
}

extension Command {
    __consuming func logging() -> Self {
        Log.pluginLoader.info("""
        \(cwd?.string ?? "")> \(executablePath) \(arguments.joined(separator: " "))
        """)

        return self
    }
}
