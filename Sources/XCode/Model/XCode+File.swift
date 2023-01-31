//
//  RelativePath.swift
//
//
//  Created by Yume on 2022/4/25.
//

import Foundation
import PathKit
import PluginInterface
import XcodeProj

// MARK: - File

public final class File {
    private unowned let project: XCodeProject
    let native: PBXFileElement

    init(native: PBXFileElement, project: XCodeProject) {
        self.native = native
        self.project = project
    }

    /// root:     /Users/xxx/git/ABCDEF
    ///
    /// fullPath: /Users/xxx/git/ABCDEF/DEF/Base.lproj/LaunchScreen.storyboard
    /// package:  DEF
    public var label: String? {
        guard let path = relativePath else {
            return nil
        }
        return project.transformToLabel(path)
    }

    public var relativePath: String? {
        let root = project.workspacePath.string
        let fullPath = fullPath ?? ""
        guard fullPath.hasPrefix(root + "/") else {
            return nil
        }
        return fullPath.delete(prefix: root + "/")
    }

    public var fullPath: String? {
        let root = project.workspacePath.string
        return try? native.fullPath(sourceRoot: root)
    }

    private var ref: PBXFileReference? {
        native as? PBXFileReference
    }

    /// File type start with `sourcecode.`
    public var isSource: Bool {
        guard let ref = ref else { return false }
        return ref.lastKnownFileType?.hasPrefix("sourcecode.") ?? false
    }

    /// File is PBXFileReference
    public var isFile: Bool {
        native is PBXFileReference
    }

    public var lastKnownFileType: LastKnownFileType? {
        .init(rawValue: ref?.lastKnownFileType ?? "")
    }

    public var explicitFileType: ExplicitFileType? {
        .init(rawValue: ref?.explicitFileType ?? "")
    }
}

extension PBXFileElement {
    func flatten() -> [PBXFileElement] {
        if let group = self as? PBXGroup {
            return group.children.flatMap { file in
                file.flatten()
            }
        }

        if let ref = self as? PBXFileReference {
            return [ref]
        }

        return []
    }
}

extension Array where Element == File {
    var labels: [String] {
        compactMap(\.label)
    }
}
