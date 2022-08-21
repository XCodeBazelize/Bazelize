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

    public func isType(_ type: LastKnownFileType) -> Bool {
        guard let ref = native as? PBXFileReference else { return false }
        return ref.lastKnownFileType == type.rawValue
    }

    // MARK: Private

    private let native: PBXFileElement
    private unowned let project: XCodeProject
}

extension PBXFileElement {
    func filterChildren(_ type: LastKnownFileType) -> [PBXFileElement] {
        if let group = self as? PBXGroup {
            return group.children.flatMap { file in
                file.filterChildren(type)
            }
        }

        if let ref = self as? PBXFileReference, ref.lastKnownFileType == type.rawValue {
            return [ref]
        }

        return []
    }
}

extension String {
    func delete(prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(dropFirst(prefix.count))
    }
}

extension Array where Element == File {
    var labels: [String] {
        compactMap(\.label)
    }
}
