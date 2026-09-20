//
//  PluginBuilder.swift
//
//
//  Created by Yume on 2022/8/24.
//

import Foundation
@preconcurrency import PathKit
import Subprocess
import System
import Util

// MARK: - PluginCompiler

/// ~/.bazelize
///     git/XCodeBazelize_Bazelize
///     build/5.6/XCodeBazelize_Bazelize/1.0.0
enum PluginCompiler {
    // MARK: Internal

    static func build(plugins: [PluginInfo]) async throws -> [PluginInfo] {
        try git.mkpath()
        try build.mkpath()

        var result: [PluginInfo] = []
        for info in plugins {
            if checkExist(plugin: info) {
                result.append(info)
                continue
            }
            do {
                try await build(plugin: info)
                result.append(info)
            } catch {
                Log.pluginLoader.warning("Build Plugin(\(info.repo)) Fail: \(error.localizedDescription)")
            }
        }
        return result
    }

    // MARK: Private

    private static let root = Path.home + ".bazelize"
    private static let git = root + "git"
    private static let build = root + "build" + swift

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
    private static func build(plugin: PluginInfo) async throws {
        let repo = git + plugin.user_repo
        if !repo.exists {
            try await run("git", "clone", plugin.url, plugin.user_repo, cwd: git)
        }

        try await run("git", "checkout", plugin.tag, cwd: repo)

        try await run("swift", "build", "-c", "release", cwd: repo)

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

extension PluginCompiler {
    fileprivate static func run(
        _ executable: String,
        _ arguments: String...,
        cwd: Path)
        async throws
    {
        Log.pluginLoader.info("""
        \(cwd.string)> \(executable) \(arguments.joined(separator: " "))
        """)

        let result = try await Subprocess.run(
            .name(executable),
            arguments: Arguments(arguments),
            workingDirectory: FilePath(cwd.string),
            output: .discarded,
            error: .currentStandardError)

        guard result.terminationStatus.isSuccess else {
            throw CommandError(
                command: "\(executable) \(arguments.joined(separator: " "))",
                status: result.terminationStatus)
        }
    }
}

// MARK: - CommandError

struct CommandError: Error, CustomStringConvertible {
    let command: String
    let status: TerminationStatus

    var description: String {
        "`\(command)` failed with \(status)"
    }
}
