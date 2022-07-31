//
//  ProjectConfig.swift
//  
//
//  Created by Yume on 2022/7/26.
//

import Foundation

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
            } else {
                return """
                "//:\(package)/\(restPath)",
                """
            }
        }
        
        return """
        "# \(path)",
        """
    }
}
