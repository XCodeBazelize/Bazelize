import Foundation
import PathKit
import XcodeProj

struct FileLoader {
    let native: PBXFileElement
    unowned let project: ProjectLoader

    var name: String? {
        native.name ?? native.path
    }

    var label: String? {
        project.transformToLabel(relativePath)
    }

    var packageName: String? {
        relativePath?.split(separator: "/").first.map(String.init)
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
            label: label,
            fileType: fileType,
            sourceTree: sourceTree,
            buildPhase: buildPhase,
            compilerFlags: compilerFlags,
            attributes: attributes
        )
    }
}

struct SynchronizedFile {
    enum Category {
        case source
        case header
        case resource
        case other
    }

    let path: String
    let fullPath: String
    let compilerFlags: String?

    var name: String {
        Path(path).lastComponent
    }

    var fileType: String? {
        switch Path(path).extension?.lowercased() {
        case "swift": return "sourcecode.swift"
        case "m": return "sourcecode.c.objc"
        case "mm": return "sourcecode.cpp.objcpp"
        case "c": return "sourcecode.c.c"
        case "cc", "cp", "cpp", "cxx": return "sourcecode.cpp.cpp"
        case "h": return "sourcecode.c.h"
        case "hh", "hpp", "hxx": return "sourcecode.cpp.h"
        case "metal": return "sourcecode.metal"
        case "xib": return "file.xib"
        case "storyboard": return "file.storyboard"
        case "xcassets": return "folder.assetcatalog"
        case "strings": return "text.plist.strings"
        case "stringsdict": return "text.plist.stringsdict"
        case "plist": return "text.plist.xml"
        case "xcframework": return "wrapper.xcframework"
        case "framework": return "wrapper.framework"
        default: return nil
        }
    }

    var category: Category {
        switch fileType {
        case "sourcecode.swift",
             "sourcecode.c.objc",
             "sourcecode.cpp.objcpp",
             "sourcecode.c.c",
             "sourcecode.cpp.cpp",
             "sourcecode.metal":
            return .source
        case "sourcecode.c.h",
             "sourcecode.cpp.h":
            return .header
        case "file.xib",
             "file.storyboard",
             "folder.assetcatalog",
             "text.plist.strings",
             "text.plist.stringsdict",
             "text.plist.xml":
            return .resource
        default:
            return .other
        }
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
        case .other: return nil
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
