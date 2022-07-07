//
//  Project.swift
//
//
//  Created by Yume on 2022/4/21.
//

import Foundation
import XcodeProj

//XcodeProj

public final class Project {
    public let native: PBXProj
    public let root: String
    
    public convenience init(proj: XcodeProj, root: String) {
        self.init(native: proj.pbxproj, root: root)
    }
    
    public init(native: PBXProj, root: String) {
        self.native = native
        self.root = root
    }
    
    private var projectConfig: ProjectConfig {
        let packages = self.native.nativeTargets.map(\.name)
        return .init(root: root, packages: packages)
    }
    
    public var targets: [Target] {
        let list = self.native.defaultConfigList
        return native.nativeTargets.map {
            Target(native: $0, defaultConfigList: list, projectConfig: projectConfig)
        }
    }
}

extension PBXProj {
    fileprivate var defaultConfigList: ConfigList? {
        let all = Set(self.configurationLists.map(ConfigList.init))
        let targets = nativeTargets.compactMap { ConfigList($0.buildConfigurationList) }
        
        return all.subtracting(targets).first
    }
}
