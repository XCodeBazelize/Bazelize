//
//  RelativePath.swift
//
//
//  Created by Yume on 2022/4/25.
//

import Foundation
import XcodeProj
import PathKit
import PluginInterface

public final class File {
    private let native: PBXFileElement
    private unowned let project: XCodeProject
    
    init(native: PBXFileElement, project: XCodeProject) {
        self.native = native
        self.project = project
    }
    
    /// root:     /Users/xxx/git/ABCDEF
    ///
    /// fullPath: /Users/xxx/git/ABCDEF/DEF/Base.lproj/LaunchScreen.storyboard
    /// package:  DEF
    public var label: String? {
        let root = project.workspacePath.string
        guard let fullPath = try? self.native.fullPath(sourceRoot: root) else {
            return nil
        }
        
        if fullPath.hasPrefix(root + "/") {
            let path = fullPath.delete(prefix: root + "/")
            return project.transformToLabel(path)
        }
        
        return """
        # "\(fullPath)",
        """
    }
}

extension Array where Element == File {
    public var labels: [String] {
        return self.compactMap(\.label)
    }
}

extension String {
    func delete(prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}
