//
//  XCode+Preffer.swift
//
//
//  Created by Yume on 2022/8/23.
//

import Foundation
import PluginInterface
import RuleBuilder
import XcodeProj

extension Dictionary where Key == String {
    fileprivate var sortedByKey: [(key: Key, value: Value)] {
        sorted { lhs, rhs in
            lhs.key < rhs.key
        }
    }
}

extension Dictionary where Key == String, Value == XCodeBuildSetting {
    public func preffer<T>(config: String = "Release", _ keypath: KeyPath<XCodeBuildSetting, T>) -> T? {
        let prefferValue = self[config]?[keyPath: keypath]
        let firstValue = sortedByKey.first?.value[keyPath: keypath]
        return prefferValue ?? firstValue
    }

    // prevent T??
    public func preffer<T>(config: String = "Release", _ keypath: KeyPath<XCodeBuildSetting, T?>) -> T? {
        let prefferValue = self[config]?[keyPath: keypath]
        let firstValue = sortedByKey.first?.value[keyPath: keypath]
        return prefferValue ?? firstValue
    }
}

extension Target {
    public func preffer<T>(config: String = "Release", _ keypath: KeyPath<XCodeBuildSetting, T>) -> T? {
        self.config.preffer(config: config, keypath)
    }

    // prevent T??
    public func preffer<T>(config: String = "Release", _ keypath: KeyPath<XCodeBuildSetting, T?>) -> T? {
        self.config.preffer(config: config, keypath)
    }
}
