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

extension SwiftPM {
    /// What a binary target ships.
    struct BinaryArtifact {
        enum Kind {
            /// A framework to link against.
            case xcframework
            /// A program to run, one build per platform.
            case artifactBundle

            init?(extension: String?) {
                switch `extension` {
                case "xcframework":
                    self = .xcframework
                case "artifactbundle":
                    self = .artifactBundle
                default:
                    return nil
                }
            }
        }

        let path: Path
        let kind: Kind
    }

    /// `info.json`: what an artifact bundle says it holds.
    struct ArtifactBundleInfo: Decodable {
        struct Artifact: Decodable {
            struct Variant: Decodable {
                /// Where the program is, inside the bundle.
                let path: String
                /// The triples it was built for; absent means anywhere.
                let supportedTriples: [String]?
            }

            /// `executable`, the only kind a bundle can hold today.
            let type: String
            let variants: [Variant]
        }

        let artifacts: [String: Artifact]
    }
}

extension SwiftPM.Generator {
    /// A binary target is what SwiftPM already fetched: an `.xcframework`,
    /// imported the way a project-owned one is, or an `.artifactbundle`, whose
    /// executable is run rather than linked.
    ///
    /// Whether an XCFramework links statically or dynamically is not in the
    /// manifest, so the binary itself is read: an archive is static, a Mach-O
    /// dylib is not.
    func buildBinary(
        _ target: SwiftPM.PackageTarget,
        in package: SwiftPM.Package,
        root: Path,
        builder: CodeBuilder) throws -> Bool
    {
        guard let artifact = artifact(of: target, in: package) else {
            Log.codeGenerate.warning("""
            Skip \(package.directory, privacy: .public)/\(target.name, privacy: .public): \
            no artifact for the binary target
            """)
            return false
        }

        /// The link keeps the artifact's name: the import rule reads the bundle
        /// name out of the path, and an artifact bundle names its executable
        /// relative to its own root.
        let directory = root + Self.artifactsRoot + target.name
        let link = directory + artifact.path.lastComponent
        try directory.mkpath()
        if link.isSymlink || link.exists {
            try? link.delete()
        }
        try link.symlink(artifact.path)

        let contents = "\(Self.artifactsRoot)/\(target.name)/**"
        let rule = ruleName(of: target.name, in: package)

        switch artifact.kind {
        case .artifactBundle:
            guard let executable = Self.executable(inArtifactBundle: artifact.path) else {
                Log.codeGenerate.warning("""
                Skip \(package.directory, privacy: .public)/\(target.name, privacy: .public): \
                the artifact bundle has no executable this machine can run
                """)
                return false
            }

            builder.load(loadableRule: Rules.Native.native_binary)
            builder.call(
                Rules.Native.Call.native_binary(
                    name: rule,
                    src: "\(Self.artifactsRoot)/\(target.name)/\(artifact.path.lastComponent)/\(executable)",
                    out: rule,
                    data: Starlark.glob([contents]),
                    tags: Self.manual,
                    visibility: .public))

        case .xcframework where isStatic(artifact.path):
            builder.load(.apple_static_xcframework_import)
            builder.call(
                Rules.Apple.General.Call.apple_static_xcframework_import(
                    name: rule,
                    xcframework_imports: Starlark.glob([contents]),
                    tags: Self.manual,
                    visibility: .public))

        case .xcframework:
            builder.load(.apple_dynamic_xcframework_import)
            builder.call(
                Rules.Apple.General.Call.apple_dynamic_xcframework_import(
                    name: rule,
                    xcframework_imports: Starlark.glob([contents]),
                    tags: Self.manual,
                    visibility: .public))
        }

        return true
    }

    static let artifactsRoot = "Artifacts"

    /// What a binary target ships, and where it ended up: a remote artifact was
    /// downloaded and unpacked into the workspace's artifact directory, a local
    /// one is a path in the package.
    func artifact(of target: SwiftPM.PackageTarget, in package: SwiftPM.Package) -> SwiftPM.BinaryArtifact? {
        var roots: [Path] = [workspace.artifacts + package.identity + target.name]

        if let path = target.path {
            roots.append(package.root + path)
        }

        for root in roots {
            if let kind = SwiftPM.BinaryArtifact.Kind(extension: root.extension), root.exists {
                return .init(path: root, kind: kind)
            }
            guard root.isDirectory else { continue }

            let children = (try? root.children()) ?? []
            for child in children.sorted(by: { $0.lastComponent < $1.lastComponent }) {
                guard let kind = SwiftPM.BinaryArtifact.Kind(extension: child.extension) else { continue }
                return .init(path: child, kind: kind)
            }
        }

        return nil
    }

    /// The executable of an artifact bundle, as a path inside the bundle.
    ///
    /// A bundle ships one variant per platform and names the triples each was
    /// built for, so the one this machine can run is the one whose triples name
    /// its architecture; a bundle that names none is taken at its word.
    static func executable(inArtifactBundle bundle: Path) -> String? {
        guard
            let data = try? Data(contentsOf: (bundle + "info.json").url),
            let info = try? JSONDecoder().decode(SwiftPM.ArtifactBundleInfo.self, from: data)
        else {
            return nil
        }

        var variants: [SwiftPM.ArtifactBundleInfo.Artifact.Variant] = []
        for name in info.artifacts.keys.sorted() {
            guard let artifact = info.artifacts[name], artifact.type == "executable" else { continue }
            variants += artifact.variants
        }

        let host = Self.hostTriple
        return variants.first { variant in
            guard let triples = variant.supportedTriples else { return true }
            return triples.contains { $0.hasPrefix(host) }
        }?.path
    }

    /// `<arch>-apple-macos`, which is how an artifact bundle spells the machine
    /// this runs on — `macosx` and a version both start with it.
    private static var hostTriple: String {
        #if arch(arm64)
        "arm64-apple-macos"
        #else
        "x86_64-apple-macos"
        #endif
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
