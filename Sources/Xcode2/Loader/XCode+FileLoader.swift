import Foundation
import PathKit
import XcodeProj

enum KnownFileType: String {
    case swift = "sourcecode.swift"
    case objc = "sourcecode.c.objc"
    case objcxx = "sourcecode.cpp.objcpp"
    case c = "sourcecode.c.c"
    case cpp = "sourcecode.cpp.cpp"
    case cHeader = "sourcecode.c.h"
    case cppHeader = "sourcecode.cpp.h"
    case metal = "sourcecode.metal"
    case staticLibrary = "archive.ar"
    case xib = "file.xib"
    case storyboard = "file.storyboard"
    case xcassets = "folder.assetcatalog"
    case strings = "text.plist.strings"
    case stringsdict = "text.plist.stringsdict"
    case plist = "text.plist.xml"
    case xcframework = "wrapper.xcframework"
    case framework = "wrapper.framework"

    init?(path: String) {
        switch Path(path).extension?.lowercased() {
        case "swift": self = .swift
        case "m": self = .objc
        case "mm": self = .objcxx
        case "c": self = .c
        case "cc", "cp", "cpp", "cxx": self = .cpp
        case "h": self = .cHeader
        case "hh", "hpp", "hxx": self = .cppHeader
        case "metal": self = .metal
        case "a": self = .staticLibrary
        case "xib": self = .xib
        case "storyboard": self = .storyboard
        case "xcassets": self = .xcassets
        case "strings": self = .strings
        case "stringsdict": self = .stringsdict
        case "plist": self = .plist
        case "xcframework": self = .xcframework
        case "framework": self = .framework
        default: return nil
        }
    }
}

struct FileLoader {
    let native: PBXFileElement
    unowned let project: ProjectLoader

    var name: String? {
        native.name ?? native.path
    }

    var packageName: String? {
        project.packageName(for: native)
    }

    var relativePath: String? {
        let root = project.workspacePath.string
        guard let fullPath else { return nil }
        guard fullPath.hasPrefix(root + "/") else { return nil }
        return fullPath.delete(prefix: root + "/")
    }

    var fullPath: String? {
        try? native.fullPath(sourceRoot: project.workspacePath.string)
    }

    var fileType: String? {
        ref?.lastKnownFileType ?? ref?.explicitFileType
    }

    var sourceTree: String {
        native.sourceTree?.description ?? ""
    }

    var frameworkName: String? {
        name?.replacingOccurrences(of: ".framework", with: "")
            .replacingOccurrences(of: ".xcframework", with: "")
    }

    var frameworkIdentity: String? {
        guard let name else { return nil }

        if name.hasSuffix(".framework") {
            return name.replacingOccurrences(of: ".framework", with: "")
        }

        if name.hasSuffix(".xcframework") {
            return name.replacingOccurrences(of: ".xcframework", with: "")
        }

        if name.hasPrefix("lib"), name.hasSuffix(".a") {
            return String(name.dropFirst(3).dropLast(2))
        }

        return name
    }

    var isSDKFramework: Bool {
        sourceTree == PBXSourceTree.sdkRoot.description ||
            sourceTree == PBXSourceTree.developerDir.description
    }

    private var ref: PBXFileReference? {
        native as? PBXFileReference
    }

    func file(buildPhase: String?, compilerFlags: String?, attributes: [String]) -> XCode.File {
        .init(
            name: name,
            path: relativePath ?? native.path,
            fullPath: fullPath,
            label: label(buildPhase: buildPhase),
            fileType: fileType,
            sourceTree: sourceTree,
            buildPhase: buildPhase,
            compilerFlags: compilerFlags,
            attributes: attributes
        )
    }

    func label(buildPhase: String?) -> String? {
        if buildPhase == BuildPhase.frameworks.rawValue, canUsePrebuiltLabel {
            return project.transformToLabel(relativePath, .prebuilt)
        }
        return project.transformToLabel(
            relativePath,
            .source(packageName: packageName)
        )
    }

    private var canUsePrebuiltLabel: Bool {
        if let typedFileType, typedFileType.isBinaryArtifact {
            return true
        }

        guard let name else { return false }
        return name.hasSuffix(".a")
    }

    private var typedFileType: KnownFileType? {
        fileType.flatMap(KnownFileType.init(rawValue:))
    }
}

struct SynchronizedFile {
    enum Category {
        case source
        case header
        case resource
        case binary
        case other
    }

    let path: String
    let fullPath: String
    let compilerFlags: String?

    var name: String {
        Path(path).lastComponent
    }

    var fileType: String? {
        typedFileType?.rawValue
    }

    var category: Category {
        typedFileType?.category ?? .other
    }

    var file: XCode.File {
        .init(
            name: name,
            path: path,
            fullPath: fullPath,
            label: nil,
            fileType: fileType,
            sourceTree: "<group>",
            buildPhase: buildPhase,
            compilerFlags: compilerFlags,
            attributes: []
        )
    }

    private var buildPhase: String? {
        switch category {
        case .source: return BuildPhase.sources.rawValue
        case .header: return BuildPhase.headers.rawValue
        case .resource: return BuildPhase.resources.rawValue
        case .binary: return nil
        case .other: return nil
        }
    }

    private var typedFileType: KnownFileType? {
        KnownFileType(path: path)
    }
}

private extension KnownFileType {
    var category: SynchronizedFile.Category {
        switch self {
        case .swift, .objc, .objcxx, .c, .cpp, .metal:
            return .source
        case .cHeader, .cppHeader:
            return .header
        case .xib, .storyboard, .xcassets, .strings, .stringsdict, .plist:
            return .resource
        case .staticLibrary, .xcframework, .framework:
            return .binary
        }
    }

    var isBinaryArtifact: Bool {
        switch self {
        case .staticLibrary, .xcframework, .framework:
            return true
        default:
            return false
        }
    }
}

extension PBXFileElement {
    func flatten() throws -> [PBXFileElement] {
        if let group = self as? PBXGroup {
            return group.children.flatMap { (try? $0.flatten()) ?? [] }
        }

        if let ref = self as? PBXFileReference {
            return [ref]
        }

        return []
    }
}

extension Sequence {
    func toDictionary<K: Hashable, V>() -> [K: V] where Element == (K, V) {
        Dictionary(uniqueKeysWithValues: self)
    }
}

func unique<T>(_ values: [T], key: (T) -> String) -> [T] {
    var result: [T] = []
    var seen = Set<String>()

    for value in values {
        let id = key(value)
        if seen.insert(id).inserted {
            result.append(value)
        }
    }

    return result
}

extension String {
    func delete(prefix: String) -> String? {
        guard hasPrefix(prefix) else { return nil }
        return String(dropFirst(prefix.count))
    }
}
