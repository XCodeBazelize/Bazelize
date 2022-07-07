//
//  RelativePath.swift
//
//
//  Created by Yume on 2022/4/25.
//

import Foundation
import XcodeProj
import PathKit

internal struct ProjectConfig {
    internal typealias Package = String
    internal let root: String
    internal let packages: [Package]
    
    internal init(root: String, packages: [Package]) {
        self.root = root
        self.packages = packages
    }
    
    private func check(_ package: Package) -> Bool {
        return self.packages.contains(package)
    }
    
    func toLabel(_ path: String?) -> String? {
        /// DEF/Base.lproj/LaunchScreen.storyboard
        guard let path = path else {return nil}
        
        if let _package = path.split(separator: "/").first {
            /// DEF
            let package = String(_package)
            /// Base.lproj/LaunchScreen.storyboard
            let restPath = path.delete(prefix: package + "/")
            
            if self.check(package) {
                return """
                "//\(package):\(restPath)",
                """
            }
        }
        
        return """
        "# \(path),"
        """
    }
}


public final class File {
    public let native: PBXFileElement
    let config: ProjectConfig
    
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
        
        let path = fullPath.delete(prefix: root + "/")
        return config.toLabel(path)
    }
}

extension Array where Element == File {
    public var labels: String {
        return self.compactMap(\.label).joined(separator: "\n")
    }
}


extension String {
    func delete(prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}
