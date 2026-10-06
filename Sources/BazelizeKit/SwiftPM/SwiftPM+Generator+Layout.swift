//
//  SwiftPM+Generator+Layout.swift
//
//
//  Where a target's sources are, and how they are linked beside its rules.
//

import BazelRules
import Foundation
@preconcurrency import PathKit
import Starlark
import Util

extension SwiftPM.Generator {
    /// The sources stay where SwiftPM put them; the package directory carries
    /// one link per target, the way a target's `Sources/` does.
    ///
    /// A link per target rather than one for the whole checkout is what keeps
    /// the rest of the checkout out of the build: a package can ship `BUILD`
    /// files of its own — swift-syntax and Yams both do — and Bazel would load
    /// them as packages of this workspace.
    func materialize(_ target: SwiftPM.PackageTarget, in package: SwiftPM.Package, at root: Path) throws -> String? {
        guard let directory = sourceDirectory(of: target, in: package) else { return nil }

        let prefix = "\(Self.sourcesRoot)/\(target.name)"
        let link = root + prefix
        try link.parent().mkpath()
        if link.isSymlink || link.exists {
            try? link.delete()
        }

        /// One link for the whole directory is what a target's sources are, but
        /// a package can keep a symlink pointing back into that directory —
        /// GRDB's test fixtures do — and Bazel cannot glob through the cycle.
        /// Such a tree is mirrored instead, entry by entry, without the link
        /// that closes the loop.
        if Self.hasCycle(directory) || Self.containsBazelPackage(directory) {
            try Self.mirror(directory, at: link)
        } else {
            try link.symlink(directory)
        }

        return prefix
    }

    /// Whether anything under the directory links back into it.
    private static func hasCycle(_ directory: Path) -> Bool {
        let root = directory.url.resolvingSymlinksInPath().path

        for entry in entries(of: directory) where entry.isSymlink {
            let resolved = entry.url.resolvingSymlinksInPath().path
            if root == resolved || root.hasPrefix("\(resolved)/") { return true }
        }

        return false
    }

    /// A linked source directory that contains its own `BUILD` file creates
    /// nested Bazel packages and hides files from the generated target. Mirror
    /// such a tree so those foreign package markers can be omitted.
    private static func containsBazelPackage(_ directory: Path) -> Bool {
        entries(of: directory).contains { packageMarkers.contains($0.lastComponent) }
    }

    /// A copy of the directory's shape, with one link per file.
    private static func mirror(_ directory: Path, at destination: Path) throws {
        try destination.mkpath()

        let root = directory.url.resolvingSymlinksInPath().path
        for child in (try? directory.children()) ?? [] {
            if packageMarkers.contains(child.lastComponent) { continue }

            let target = destination + child.lastComponent

            if child.isSymlink {
                let resolved = child.url.resolvingSymlinksInPath().path
                /// The link that closes the loop; SwiftPM ignores it too.
                if root == resolved || root.hasPrefix("\(resolved)/") { continue }
            }

            if child.isDirectory {
                try mirror(child, at: target)
            } else {
                try target.symlink(child)
            }
        }
    }

    /// Everything under a directory, links included and not followed.
    private static func entries(of directory: Path) -> [Path] {
        let children = (try? directory.children()) ?? []

        return children.flatMap { child -> [Path] in
            guard !child.isSymlink, child.isDirectory else { return [child] }
            return [child] + entries(of: child)
        }
    }

    private static let packageMarkers: Set = ["BUILD", "BUILD.bazel"]

    static let sourcesRoot = "Sources"

    /// A package rule is built through the bundle rule that transitions it to a
    /// platform; on its own an iOS-only package would be compiled for the host,
    /// so no wildcard pattern may pick one up.
    static let manual = ["manual"]

    /// The extensions of the files that actually belong to the target, which is
    /// what decides whether a `regular` target is Swift or C-family.
    func extensions(of target: SwiftPM.PackageTarget, in package: SwiftPM.Package) -> Set<String> {
        Set(sourceFiles(of: target, in: package).compactMap(\.extension))
    }

    /// The files SwiftPM compiles for the target: what an explicit `sources`
    /// list names, or the whole target directory, minus `exclude`.
    func sourceFiles(of target: SwiftPM.PackageTarget, in package: SwiftPM.Package) -> [Path] {
        guard let directory = sourceDirectory(of: target, in: package) else { return [] }
        let roots = (target.sources?.nonEmpty?.map { directory + $0 }) ?? [directory]
        return files(under: roots, excluding: target.exclude, in: directory)
    }

    /// Every file under a directory.
    ///
    /// `FileManager.subpathsOfDirectory` returns nothing when the directory
    /// itself is a symlink, and a package can point one target at another's
    /// sources that way to build a variant of it. Paths stay under the
    /// directory as named, because that is what a glob pattern is built from.
    static func walk(_ directory: Path) -> [Path] {
        var visited: Set<String> = []
        return walk(directory, visited: &visited)
    }

    private static func walk(_ directory: Path, visited: inout Set<String>) -> [Path] {
        /// A package's test fixtures can link a directory back to an ancestor,
        /// which would otherwise be walked forever.
        let resolved = directory.url.resolvingSymlinksInPath().path
        guard visited.insert(resolved).inserted else { return [] }

        let children = (try? directory.children()) ?? []
        return children.flatMap { child -> [Path] in
            child.isDirectory ? walk(child, visited: &visited) : [child]
        }
    }

    /// The target's files as paths under its source link, which is what a glob
    /// pattern is matched against.
    func relativeFiles(
        of target: SwiftPM.PackageTarget,
        in package: SwiftPM.Package,
        prefix: String,
        excluding exclude: Bool = true) -> [String]
    {
        guard let directory = sourceDirectory(of: target, in: package) else { return [] }
        let root = directory.normalize().string
        let files = exclude
            ? allFiles(of: target, in: package)
            : Self.walk(directory)

        return files.compactMap { file in
            let path = file.normalize().string
            guard path.hasPrefix(root) else { return nil }
            return prefix + String(path.dropFirst(root.count))
        }
    }

    /// Everything in the target directory, `exclude` aside.
    ///
    /// An explicit `sources` list only stops SwiftPM from compiling the rest;
    /// a header next to those sources is still the target's header, which is
    /// why it is collected from the whole directory.
    func allFiles(of target: SwiftPM.PackageTarget, in package: SwiftPM.Package) -> [Path] {
        guard let directory = sourceDirectory(of: target, in: package) else { return [] }
        return files(under: [directory], excluding: target.exclude, in: directory)
    }

    private func files(under roots: [Path], excluding exclude: [String], in directory: Path) -> [Path] {
        let excluded = exclude.map { (directory + $0).normalize().string }

        var files: [Path] = []
        for root in roots {
            if root.isDirectory {
                files.append(contentsOf: Self.walk(root))
            } else if root.exists {
                files.append(root)
            }
        }

        return files.filter { file in
            let path = file.normalize().string
            return !excluded.contains { path == $0 || path.hasPrefix("\($0)/") }
        }
    }

    /// Extensions a C-family compiler is handed.
    static let compileExtensions = ["c", "cc", "cpp", "cxx", "m", "mm", "S", "s"]
    /// Extensions that are only ever included by another file.
    static let headerExtensions = ["h", "hh", "hpp", "hxx", "inc"]

    /// SwiftPM's own layout rules: an explicit `path`, else one of the
    /// conventional directories, else the package root for a single target.
    func sourceDirectory(of target: SwiftPM.PackageTarget, in package: SwiftPM.Package) -> Path? {
        if let path = target.path {
            let directory = (package.root + path).normalize()
            return directory.exists ? directory : nil
        }

        /// A test target is looked for under `Tests` first, the way SwiftPM
        /// looks for it, and a plugin under `Plugins`.
        let conventional = ["Sources", "Source", "src", "srcs"]
        let candidates: [String]
        switch target.type {
        case "test":
            candidates = ["Tests"] + conventional
        case "plugin":
            candidates = ["Plugins"] + conventional
        default:
            candidates = conventional
        }

        for candidate in candidates {
            let directory = package.root + candidate + target.name
            if directory.exists { return directory }
        }

        /// `Sources` itself, with the files in it and no directory of the
        /// target's own: SwiftPM allows that when nothing else could claim
        /// them, which is a package with one target of that kind.
        guard Self.isOnlyTarget(target, in: package) else { return nil }

        for candidate in candidates {
            let directory = package.root + candidate
            if directory.isDirectory { return directory }
        }

        return nil
    }

    /// Whether the package has no other target that a bare source
    /// directory could belong to: a test target does not take `Tests` from
    /// another test target, and a library does not take `Sources` from
    /// another library.
    private static func isOnlyTarget(_ target: SwiftPM.PackageTarget, in package: SwiftPM.Package) -> Bool {
        let sameKind = package.manifest.targets.filter { other in
            switch (other.type, target.type) {
            case ("test", "test"), ("plugin", "plugin"):
                return true
            case ("test", _), (_, "test"), ("plugin", _), (_, "plugin"):
                return false
            default:
                return true
            }
        }

        return sameKind.count == 1
    }
}
