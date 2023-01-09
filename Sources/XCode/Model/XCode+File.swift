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
    // MARK: Lifecycle

    init(native: PBXFileElement, project: XCodeProject) {
        self.native = native
        self.project = project
    }

    // MARK: Public

    /// root:     /Users/xxx/git/ABCDEF
    ///
    /// fullPath: /Users/xxx/git/ABCDEF/DEF/Base.lproj/LaunchScreen.storyboard
    /// package:  DEF
    public var label: String? {
        let root = project.workspacePath.string
        guard let fullPath = try? native.fullPath(sourceRoot: root) else {
            return nil
        }

        if fullPath.hasPrefix(root + "/") {
            let path = fullPath.delete(prefix: root + "/")
            return project.transformToLabel(path)
        }

        return """
        # \(fullPath)
        """
    }

    /// File type start with `sourcecode.`
    public var isSource: Bool {
        guard let ref = native as? PBXFileReference else { return false }
        return ref.lastKnownFileType?.hasPrefix("sourcecode.") ?? false
    }

    /// File is PBXFileReference
    public var isFile: Bool {
        native is PBXFileReference
    }


    public var type: LastKnownFileType? {
        guard let ref = native as? PBXFileReference else { return nil }
        return .init(rawValue: ref.lastKnownFileType ?? "")
    }

    public func isType(_ type: LastKnownFileType) -> Bool {
        guard let ref = native as? PBXFileReference else { return false }
        return ref.lastKnownFileType == type.rawValue
    }

    // MARK: Private

    private let native: PBXFileElement
    private unowned let project: XCodeProject
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
