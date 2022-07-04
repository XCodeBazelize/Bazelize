//
//  ConfigList.swift
//  
//
//  Created by Yume on 2022/7/1.
//

import Foundation
import XcodeProj

public struct ConfigList {
    public let list: XCConfigurationList?
    
    public init(_ target: PBXNativeTarget) {
        self.init(target.buildConfigurationList)
    }
    
    public init(_ list: XCConfigurationList?) {
        self.list = list
    }
    
    /// Release / Debug / More...
    public subscript(name: String) -> BuildSetting? {
        guard let config = list?.configuration(name: name) else { return nil }
        return .init(config)
    }
    
    public var buildSettings: [BuildSetting] {
        list?.buildConfigurations.map(BuildSetting.init) ?? []
    }
    
    public var configs: [String] {
        buildSettings.map(\.config.name)
    }
}

extension ConfigList: Hashable {
    public static func == (lhs: ConfigList, rhs: ConfigList) -> Bool {
        return lhs.list?.uuid == rhs.list?.uuid
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(list?.uuid)
    }
}
