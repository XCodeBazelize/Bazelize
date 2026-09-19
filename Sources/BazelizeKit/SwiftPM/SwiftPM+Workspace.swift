//
//  SwiftPM+Workspace.swift
//
//
//  Resolving the packages a project depends on and reading their manifests.
//

import Foundation
@preconcurrency import PathKit
import Subprocess
import System
import Util

extension SwiftPM {
    /// A package as the generator sees it: where its sources are, what it declares,
    /// and the directory its products are exposed under.
    struct Package {
        /// The directory under `Packages/`, named the way a human refers to the
        /// package.
        let directory: String
        /// The checkout the sources come from.
        let root: Path
        let manifest: Manifest
        /// `true` for a package in the project's own repository.
        let isLocal: Bool
        /// `true` for the package that was handed to bazelize, as opposed to one
        /// something else depends on.
        let isRoot: Bool

        /// The name SwiftPM files the package's artifacts under.
        var identity: String {
            directory.lowercased()
        }
    }

    /// Everything the generator needs about one project's package graph.
    struct Workspace {
        let packages: [Package]

        /// Where SwiftPM unpacked the binary targets it fetched.
        let artifacts: Path

        /// Which directory a package identity or manifest name resolves to, so a
        /// product dependency can be turned into a label.
        let directoryByIdentity: [String: String]
    }
}

extension SwiftPM {
    /// Resolves the workspace `Package.swift` and reads every checkout's manifest.
    ///
    /// SwiftPM owns resolution: it already wrote `Package.resolved`, and its
    /// checkouts are the sources the rules will point at. `dump-package` is read
    /// per checkout because it is the manifest SwiftPM itself evaluated — cheap,
    /// offline, and it spans every tools version in the graph.
    ///
    /// `locals` are the packages of the project's own repository, the same ones the
    /// generated manifest declares as `path:` dependencies. They are handed in
    /// rather than read back out of that manifest: the caller that wrote it knows
    /// them.
    static func loadWorkspace(output: Path, root input: Path?, locals: [Path]) async throws -> Workspace {
        /// A project with no packages has no manifest written for it, and asking
        /// SwiftPM to resolve one is an error rather than an empty graph.
        guard (output + "Package.swift").exists else {
            return .init(
                packages: [],
                artifacts: output + ".build/artifacts",
                directoryByIdentity: [:])
        }

        try await resolve(output: output)

        let checkouts = output + ".build/checkouts"
        var packages: [Package] = []
        var directoryByIdentity: [String: String] = [:]

        for root in try roots(checkouts: checkouts, locals: locals) {
            guard let manifest = try await manifest(at: root.path) else { continue }

            let package = Package(
                directory: root.directory,
                root: root.path,
                manifest: manifest,
                isLocal: root.isLocal,
                /// Both sides are made absolute: the output can be a relative path,
                /// and the package handed in is named however the caller named it.
                isRoot: input.map { $0.absolute().normalize() == root.path.absolute().normalize() } ?? false)
            packages.append(package)

            for identity in [manifest.name, root.directory, root.path.lastComponent] {
                directoryByIdentity[identity.lowercased()] = root.directory
            }
        }

        return .init(
            packages: packages,
            artifacts: output + ".build/artifacts",
            directoryByIdentity: directoryByIdentity)
    }

    // MARK: Private

    private struct Root {
        let directory: String
        let path: Path
        let isLocal: Bool
    }

    /// `swift package resolve` fetches what `Package.resolved` pins; without it
    /// there are no checkouts to read.
    private static func resolve(output: Path) async throws {
        Log.codeGenerate.info("swift package resolve at \(output.string, privacy: .public)")

        let result = try await Subprocess.run(
            .name("swift"),
            arguments: Arguments(["package", "resolve"]),
            workingDirectory: FilePath(output.string),
            output: .discarded,
            error: .currentStandardError)

        guard result.terminationStatus.isSuccess else {
            throw SwiftPMError.resolveFailed(status: "\(result.terminationStatus)")
        }
    }

    /// Remote packages live in `.build/checkouts`; a local one is wherever its
    /// manifest is, and is read in place.
    private static func roots(checkouts: Path, locals: [Path]) throws -> [Root] {
        var roots: [Root] = []

        if checkouts.exists {
            for child in try checkouts.children() where child.isDirectory {
                roots.append(.init(directory: child.lastComponent, path: child, isLocal: false))
            }
        }

        for path in locals {
            let root = path.absolute().normalize()
            guard root.exists else { continue }
            roots.append(.init(directory: root.lastComponent, path: root, isLocal: true))
        }

        return roots.sorted { $0.directory < $1.directory }
    }

    private static func manifest(at root: Path) async throws -> Manifest? {
        let result = try await Subprocess.run(
            .name("swift"),
            arguments: Arguments(["package", "dump-package", "--package-path", root.string]),
            output: .data(limit: 32 * 1024 * 1024),
            error: .discarded)

        guard result.terminationStatus.isSuccess else {
            Log.codeGenerate.warning("""
            No manifest for \(root.lastComponent, privacy: .public): dump-package failed
            """)
            return nil
        }

        do {
            return try JSONDecoder().decode(Manifest.self, from: Data(result.standardOutput))
        } catch {
            Log.codeGenerate.warning("""
            Cannot read the manifest of \(root.lastComponent, privacy: .public): \
            \(error.localizedDescription, privacy: .public)
            """)
            return nil
        }
    }
}

// MARK: - SwiftPMError

enum SwiftPMError: Error, CustomStringConvertible {
    case resolveFailed(status: String)

    var description: String {
        switch self {
        case .resolveFailed(let status):
            return "swift package resolve failed: \(status)"
        }
    }
}
