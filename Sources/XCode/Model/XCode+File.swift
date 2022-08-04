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

public final class File {
    private let native: PBXFileElement
    private unowned let project: XCodeProject

    init(native: PBXFileElement, project: XCodeProject) {
        self.native = native
        self.project = project
    }

    public func isType(_ type: LastKnownFileType) -> Bool {
        guard let ref = self.native as? PBXFileReference else { return false }
        return ref.lastKnownFileType == type.rawValue
    }

    /// root:     /Users/xxx/git/ABCDEF
    ///
    /// fullPath: /Users/xxx/git/ABCDEF/DEF/Base.lproj/LaunchScreen.storyboard
    /// package:  DEF
    public var label: String? {
        let root = self.project.workspacePath.string
        guard let fullPath = try? self.native.fullPath(sourceRoot: root) else {
            return nil
        }

        if fullPath.hasPrefix(root + "/") {
            let path = fullPath.delete(prefix: root + "/")
            return self.project.transformToLabel(path)
        }

        return """
        # "\(fullPath)",
        """
    }
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
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}

extension Array where Element == File {
    var labels: [String] {
        return self.compactMap(\.label)
    }
}
