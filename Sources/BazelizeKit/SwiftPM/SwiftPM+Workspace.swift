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

        /// Which traits each package is built with unless the build says
        /// otherwise, by identity.
        let traits: [String: Set<String>]
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
    static func loadWorkspace(
        output: Path,
        root input: Path?,
        locals: [Path],
        platforms: Set<String> = []) async throws -> Workspace
    {
        /// A project with no packages has no manifest written for it, and asking
        /// SwiftPM to resolve one is an error rather than an empty graph.
        guard (output + "Package.swift").exists else {
            return .init(
                packages: [],
                artifacts: output + ".build/artifacts",
                directoryByIdentity: [:],
                traits: [:])
        }

        try await resolve(output: output)

        let scratch = output + ".build"
        var manifests: [(root: Root, manifest: Manifest)] = []
        var directoryByIdentity: [String: String] = [:]

        /// A worklist rather than a list: a package read in place can declare
        /// `path:` dependencies of its own, and those are not in
        /// `.build/checkouts` either — the manifest that declares one is the
        /// only thing that knows where it is.
        var pending = try roots(scratch: scratch, locals: locals)
        var seen: Set<String> = []

        while !pending.isEmpty {
            let root = pending.removeFirst()
            guard seen.insert(root.path.string).inserted else { continue }
            guard let manifest = try await manifest(at: root.path) else { continue }
            manifests.append((root, manifest))

            for identity in [manifest.name] + root.identities {
                directoryByIdentity[identity.lowercased()] = root.directory
            }

            for dependency in manifest.dependencies {
                guard let path = dependency.path else { continue }
                let local = Path(path).absolute().normalize()
                guard local.isDirectory else { continue }
                pending.append(.init(directory: local.lastComponent, path: local, isLocal: true))
            }
        }
        manifests.sort { $0.root.directory < $1.root.directory }

        /// Which traits are on is a property of the graph, not of one manifest,
        /// so it is answered once every manifest is read. It is what the flag
        /// of each trait defaults to, not something resolved away here.
        let traits = enabledTraits(
            of: manifests.map { (identity: $0.root.directory.lowercased(), manifest: $0.manifest) },
            directoryByIdentity: directoryByIdentity)
        let packages = manifests.map { entry in
            Package(
                directory: entry.root.directory,
                root: entry.root.path,
                manifest: entry.manifest.resolving(platforms: platforms),
                isLocal: entry.root.isLocal,
                /// Both sides are made absolute: the output can be a relative path,
                /// and the package handed in is named however the caller named it.
                isRoot: input.map { $0.absolute().normalize() == entry.root.path.absolute().normalize() } ?? false)
        }

        return .init(
            packages: packages,
            artifacts: output + ".build/artifacts",
            directoryByIdentity: directoryByIdentity,
            traits: traits)
    }

    /// The traits each package is built with, by identity.
    ///
    /// A package gets its own default traits unless something that depends on it
    /// names a selection instead. An explicit empty selection disables defaults;
    /// `.defaults` is encoded as the trait named `default`. A trait can enable
    /// further traits, so the set is closed over that.
    static func enabledTraits(
        of manifests: [(identity: String, manifest: Manifest)],
        directoryByIdentity: [String: String]) -> [String: Set<String>]
    {
        /// A dependency names the package by SwiftPM's identity for it, which is
        /// not always the directory the package is filed under.
        func identity(of dependency: Dependency) -> String {
            directoryByIdentity[dependency.identity]?.lowercased() ?? dependency.identity
        }

        var requested: [String: Set<String>] = [:]
        for entry in manifests {
            for dependency in entry.manifest.dependencies {
                let dependencyIdentity = identity(of: dependency)
                requested[dependencyIdentity, default: []].formUnion(dependency.traits)
            }
        }

        var enabled: [String: Set<String>] = [:]
        for entry in manifests {
            /// Nothing asked for anything in particular, so the defaults are what
            /// is on — as they are for the package the tool was pointed at.
            let names = requested[entry.identity] ?? ["default"]
            enabled[entry.identity] = close(names, in: entry.manifest)
        }
        return enabled
    }

    /// A trait can enable other traits, and `default` is the trait a build that
    /// asks for nothing gets. Neither is a define, so `default` is not part of
    /// the answer.
    private static func close(_ names: Set<String>, in manifest: Manifest) -> Set<String> {
        let byName = Dictionary(manifest.traits.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })

        var enabled: Set<String> = []
        var pending = Array(names)
        while let name = pending.popLast() {
            guard enabled.insert(name).inserted else { continue }
            pending += byName[name]?.enabledTraits ?? []
        }

        enabled.remove("default")
        return enabled
    }

    // MARK: Internal

    struct Root {
        let directory: String
        let path: Path
        let isLocal: Bool
        /// What a dependency can call this package, beside its manifest's own
        /// name: the directory it is filed under, and — for one downloaded from
        /// a registry — the name inside its scope.
        let identities: [String]

        init(directory: String, path: Path, isLocal: Bool, identities: [String]? = nil) {
            self.directory = directory
            self.path = path
            self.isLocal = isLocal
            self.identities = identities ?? [directory, path.lastComponent]
        }
    }

    /// Where the packages of a resolved workspace are.
    ///
    /// A package from source control is a checkout, a local one is read in
    /// place, and one from a registry is an archive SwiftPM unpacked under
    /// `registry/downloads/<scope>/<name>/<version>` — the version is the
    /// directory, so what names the package is the two above it.
    static func roots(scratch: Path, locals: [Path]) throws -> [Root] {
        var roots: [Root] = []

        let checkouts = scratch + "checkouts"
        if checkouts.exists {
            for child in try checkouts.children() where child.isDirectory {
                roots.append(.init(directory: child.lastComponent, path: child, isLocal: false))
            }
        }

        let downloads = scratch + "registry/downloads"
        if downloads.exists {
            for scope in try downloads.children() where scope.isDirectory {
                for package in try scope.children() where package.isDirectory {
                    /// One version is resolved, and a stale one is left behind:
                    /// the one with a manifest is the one that was unpacked.
                    let versions = try package.children()
                        .filter { ($0 + "Package.swift").exists }
                        .sorted { $0.lastComponent < $1.lastComponent }
                    guard let version = versions.last else { continue }

                    let identity = "\(scope.lastComponent).\(package.lastComponent)"
                    roots.append(.init(
                        directory: identity,
                        path: version,
                        isLocal: false,
                        identities: [identity, package.lastComponent]))
                }
            }
        }

        for path in locals {
            let root = path.absolute().normalize()
            guard root.exists else { continue }
            roots.append(.init(directory: root.lastComponent, path: root, isLocal: true))
        }

        return roots.sorted { $0.directory < $1.directory }
    }

    // MARK: Private

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
