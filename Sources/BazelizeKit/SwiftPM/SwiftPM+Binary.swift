//
//  SwiftPM+Binary.swift
//
//
//  Rules for a package target that ships a built binary.
//

import BazelRules
import Foundation
@preconcurrency import PathKit
import Starlark
import Util

extension SwiftPM.Generator {
    /// A binary target is an `.xcframework` SwiftPM already fetched, imported the
    /// way a project-owned one is.
    ///
    /// Whether it links statically or dynamically is not in the manifest, so the
    /// binary itself is read: an archive is static, a Mach-O dylib is not.
    func buildBinary(
        _ target: SwiftPM.PackageTarget,
        in package: SwiftPM.Package,
        root: Path,
        builder: CodeBuilder) throws -> Bool
    {
        guard let xcframework = try artifact(of: target, in: package) else {
            Log.codeGenerate.warning("""
            Skip \(package.directory, privacy: .public)/\(target.name, privacy: .public): \
            no artifact for the binary target
            """)
            return false
        }

        /// The link keeps the `.xcframework` name: the import rule reads the
        /// bundle name out of the path.
        let directory = root + Self.artifactsRoot + target.name
        let link = directory + xcframework.lastComponent
        try directory.mkpath()
        if link.isSymlink || link.exists {
            try? link.delete()
        }
        try link.symlink(xcframework)

        let imports = Starlark.glob([
            "\(Self.artifactsRoot)/\(target.name)/**",
        ])

        if isStatic(xcframework) {
            builder.load(.apple_static_xcframework_import)
            builder.call(
                Rules.Apple.General.Call.apple_static_xcframework_import(
                    name: target.name,
                    xcframework_imports: imports,
                    visibility: .public))
        } else {
            builder.load(.apple_dynamic_xcframework_import)
            builder.call(
                Rules.Apple.General.Call.apple_dynamic_xcframework_import(
                    name: target.name,
                    xcframework_imports: imports,
                    visibility: .public))
        }

        return true
    }

    static let artifactsRoot = "Artifacts"

    /// Where the artifact ended up: a remote one was downloaded and unpacked into
    /// the workspace's artifact directory, a local one is a path in the package.
    private func artifact(of target: SwiftPM.PackageTarget, in package: SwiftPM.Package) throws -> Path? {
        var roots: [Path] = [workspace.artifacts + package.identity + target.name]

        if let path = target.path {
            roots.append(package.root + path)
        }

        for root in roots {
            if root.extension == "xcframework", root.exists { return root }
            guard root.isDirectory else { continue }

            let children = (try? root.children()) ?? []
            if let xcframework = children.first(where: { $0.extension == "xcframework" }) {
                return xcframework
            }
        }

        return nil
    }

    /// The framework inside the slice is either a static archive — `!<arch>` — or a
    /// Mach-O dylib. Reading the first bytes beats guessing from the name.
    private func isStatic(_ xcframework: Path) -> Bool {
        let slices = ((try? xcframework.children()) ?? []).filter(\.isDirectory)

        for slice in slices {
            let entries = (try? slice.children()) ?? []

            if entries.contains(where: { $0.extension == "a" }) { return true }

            guard let framework = entries.first(where: { $0.extension == "framework" }) else {
                continue
            }
            let binary = framework + framework.lastComponentWithoutExtension
            guard let handle = FileHandle(forReadingAtPath: binary.string) else { continue }
            defer { try? handle.close() }

            let magic = try? handle.read(upToCount: 8)
            return magic?.starts(with: Array("!<arch>".utf8)) ?? false
        }

        return false
    }
}
