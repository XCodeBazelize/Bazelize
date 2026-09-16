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
                    name: ruleName(of: target.name, in: package),
                    xcframework_imports: imports,
                    tags: Self.manual,
                    visibility: .public))
        } else {
            builder.load(.apple_dynamic_xcframework_import)
            builder.call(
                Rules.Apple.General.Call.apple_dynamic_xcframework_import(
                    name: ruleName(of: target.name, in: package),
                    xcframework_imports: imports,
                    tags: Self.manual,
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

    /// Whether the framework in the slice links statically, read from the binary
    /// itself: the manifest does not say, and a static archive handed to the
    /// dynamic import rule fails in the bitcode stripper.
    private func isStatic(_ xcframework: Path) -> Bool {
        let slices = ((try? xcframework.children()) ?? []).filter(\.isDirectory)

        for slice in slices {
            let entries = (try? slice.children()) ?? []

            if entries.contains(where: { $0.extension == "a" }) { return true }

            guard let framework = entries.first(where: { $0.extension == "framework" }) else {
                continue
            }
            let binary = framework + framework.lastComponentWithoutExtension
            guard let data = try? Data(contentsOf: binary.url) else { continue }

            return Self.isStatic(binary: data, offset: 0)
        }

        return false
    }

    /// A binary is an archive, a fat file wrapping one per architecture, or a
    /// Mach-O image whose type says whether it is a dylib.
    private static func isStatic(binary: Data, offset: Int) -> Bool {
        guard let magic = binary.marker(at: offset) else { return false }

        switch magic {
        case Self.fat32, Self.fat64:
            /// A fat header is followed by one entry per architecture, each naming
            /// the offset of its image; every slice of one file is of the same
            /// kind, so the first answers. The 64-bit entry has a 64-bit offset,
            /// whose low word is the one that can address the file.
            let field = magic == Self.fat64 ? offset + 20 : offset + 16
            guard let slice = binary.word(at: field, littleEndian: false) else { return false }
            return isStatic(binary: binary, offset: Int(slice))

        case Self.machOBigEndian32, Self.machOBigEndian64:
            return binary.fileType(at: offset, littleEndian: false) != Self.dylib

        case Self.machOLittleEndian32, Self.machOLittleEndian64:
            return binary.fileType(at: offset, littleEndian: true) != Self.dylib

        default:
            /// Neither Mach-O nor fat: a static archive, which is what a static
            /// framework's binary is.
            return binary.starts(with: Array("!<arch>".utf8), at: offset)
        }
    }

    private static let fat32: UInt32 = 0xCAFE_BABE
    private static let fat64: UInt32 = 0xCAFE_BABF
    private static let machOBigEndian32: UInt32 = 0xFEED_FACE
    private static let machOBigEndian64: UInt32 = 0xFEED_FACF
    private static let machOLittleEndian32: UInt32 = 0xCEFA_EDFE
    private static let machOLittleEndian64: UInt32 = 0xCFFA_EDFE
    /// `MH_DYLIB`.
    private static let dylib: UInt32 = 6
}

extension Data {
    /// The four bytes at an offset in file order, which is what a magic number is.
    fileprivate func marker(at offset: Int) -> UInt32? {
        word(at: offset, littleEndian: false)
    }

    /// `filetype`, the third word of a Mach-O header.
    fileprivate func fileType(at offset: Int, littleEndian: Bool) -> UInt32? {
        word(at: offset + 12, littleEndian: littleEndian)
    }

    /// A 32-bit field, in the image's own byte order.
    fileprivate func word(at offset: Int, littleEndian: Bool) -> UInt32? {
        guard offset >= 0, count >= offset + 4 else { return nil }

        let start = index(startIndex, offsetBy: offset)
        let bytes = Array(self[start ..< index(start, offsetBy: 4)])
        /// Folding from the most significant byte: the first byte in a big-endian
        /// field, the last in a little-endian one.
        return (littleEndian ? Array(bytes.reversed()) : bytes)
            .reduce(UInt32(0)) { result, byte in
                result << 8 | UInt32(byte)
            }
    }

    fileprivate func starts(with prefix: [UInt8], at offset: Int) -> Bool {
        guard count >= offset + prefix.count else { return false }
        let start = index(startIndex, offsetBy: offset)
        return Array(self[start ..< index(start, offsetBy: prefix.count)]) == prefix
    }
}
