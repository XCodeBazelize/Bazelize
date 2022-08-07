//
//  ConfigList.swift
//
//
//  Created by Yume on 2022/7/1.
//

import Foundation
import PluginInterface
import XcodeProj

// MARK: - ConfigList

struct ConfigList {
    // MARK: Lifecycle


    init(_ target: PBXNativeTarget) {
        self.init(target.buildConfigurationList)
    }

    init(_ list: XCConfigurationList?) {
        native = list
    }

    // MARK: Internal


    var buildSettings: [String: BuildSetting] {
        let pair = (native?.buildConfigurations.map(BuildSetting.init) ?? []).map {
            ($0.name, $0)
        }

        return Dictionary(pair, uniquingKeysWith: { first, _ in first })
    }


    /// For XCode Target ConfigList merge default ConfigList
    func merge(_ config: ConfigList?) -> [String: BuildSetting] {
        guard let config = config else {
            return buildSettings
        }

        let `default` = config.buildSettings
        return buildSettings.mapValues { setting in
            setting.merge(`default`[setting.name])
        }
    }

    // MARK: Private

    private let native: XCConfigurationList?
}

// MARK: Hashable

extension ConfigList: Hashable {
    public static func == (lhs: ConfigList, rhs: ConfigList) -> Bool {
        lhs.native?.uuid == rhs.native?.uuid
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(native?.uuid)
    }
}
