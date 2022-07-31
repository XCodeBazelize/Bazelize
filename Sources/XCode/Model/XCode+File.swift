//
//  RelativePath.swift
//
//
//  Created by Yume on 2022/4/25.
//

import Foundation
import XcodeProj
import PathKit

public final class File {
    private let native: PBXFileElement
    private let config: ProjectConfig
    
    init(native: PBXFileElement, config: ProjectConfig) {
        self.native = native
        self.config = config
    }
    
    /// root:     /Users/xxx/git/ABCDEF
    ///
    /// fullPath: /Users/xxx/git/ABCDEF/DEF/Base.lproj/LaunchScreen.storyboard
    /// package:  DEF
    public var label: String? {
        let root = config.root
        guard let fullPath = try? self.native.fullPath(sourceRoot: root) else {
            return nil
        }
        
        if fullPath.hasPrefix(root + "/") {
            let path = fullPath.delete(prefix: root + "/")
            return config.toLabel(path)
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
