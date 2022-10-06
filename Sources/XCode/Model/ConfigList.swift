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

    init(_ project: Project, _ target: PBXNativeTarget) {
        self.init(project, target.buildConfigurationList)
    }

    init(_ project: Project, _ list: XCConfigurationList?) {
        self.project = project
        native = list
    }

    // MARK: Public

    public unowned let project: Project

    // MARK: Internal

    var buildSettings: [String: BuildSetting] {
        let pair: [(String, BuildSetting)] = native?.buildConfigurations
            .map {
                BuildSetting(project, $0)
            }.map {
                ($0.name, $0)
            } ?? []

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
