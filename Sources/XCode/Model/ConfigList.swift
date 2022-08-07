//
//  ConfigList.swift
//  
//
//  Created by Yume on 2022/7/1.
//

import Foundation
import XcodeProj
import PluginInterface

struct ConfigList {
    private let native: XCConfigurationList?
    
    init(_ target: PBXNativeTarget) {
        self.init(target.buildConfigurationList)
    }
    
    init(_ list: XCConfigurationList?) {
        self.native = list
    }
    
    var buildSettings: [String: BuildSetting] {
        let pair = (native?.buildConfigurations.map(BuildSetting.init) ?? []).map {
            ($0.name, $0)
        }
        
        return Dictionary(pair, uniquingKeysWith: { (first, _) in first })
    }
    
    /// For XCode Target ConfigList merge default ConfigList
    func merge(_ config: ConfigList?) -> [String: BuildSetting] {
        guard let config = config else {
            return self.buildSettings
        }
        
        let `default` = config.buildSettings
        return self.buildSettings.mapValues { setting in
            return setting.merge(`default`[setting.name])
        }
    }
}

extension ConfigList: Hashable {
    public static func == (lhs: ConfigList, rhs: ConfigList) -> Bool {
        return lhs.native?.uuid == rhs.native?.uuid
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(native?.uuid)
    }
}
