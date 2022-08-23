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
    public func preffer<T>(config: String?, _ keyPath: KeyPath<XCodeBuildSetting, T>) -> T? {
        let firstValue = sortedByKey.first?.value[keyPath: keyPath]
        guard let key = config else { return firstValue }
        let prefferValue = self[key]?[keyPath: keyPath]
        return prefferValue ?? firstValue
    }

    // prevent T??
    public func preffer<T>(config: String?, _ keyPath: KeyPath<XCodeBuildSetting, T?>) -> T? {
        let firstValue = sortedByKey.first?.value[keyPath: keyPath]
        guard let key = config else { return firstValue }
        let prefferValue = self[key]?[keyPath: keyPath]
        return prefferValue ?? firstValue
    }
}

extension Target {
    public func preffer<T>(_ keyPath: KeyPath<XCodeBuildSetting, T>) -> T? {
        config.preffer(config: project.prefferConfig, keyPath)
    }

    // prevent T??
    public func preffer<T>(_ keyPath: KeyPath<XCodeBuildSetting, T?>) -> T? {
        config.preffer(config: project.prefferConfig, keyPath)
    }
}
