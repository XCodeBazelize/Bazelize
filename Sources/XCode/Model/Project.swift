//
//  Project.swift
//  
//
//  Created by Yume on 2022/4/21.
//

import Foundation
import XcodeProj

public protocol Project {
    var targets: [Target] {get}
}

extension PBXProj: Project {
    public var defaultConfigList: ConfigList? {
        let all = Set(self.configurationLists.map(ConfigList.init))
        let targets = nativeTargets.compactMap { ConfigList($0.buildConfigurationList) }
        
        return all.subtracting(targets).first
    }
    
    public var targets: [Target] {
        let list = self.defaultConfigList
        return nativeTargets.map {
            Target(native: $0, defaultConfigList: list)
        }
    }
}
