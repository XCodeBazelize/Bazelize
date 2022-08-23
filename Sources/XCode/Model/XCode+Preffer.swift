//
//  XCode+Prefer.swift
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
    public func prefer<T>(config: String?, _ keyPath: KeyPath<XCodeBuildSetting, T>) -> T? {
        let firstValue = sortedByKey.first?.value[keyPath: keyPath]
        guard let key = config else { return firstValue }
        let preferValue = self[key]?[keyPath: keyPath]
        return preferValue ?? firstValue
    }

    // prevent T??
    public func prefer<T>(config: String?, _ keyPath: KeyPath<XCodeBuildSetting, T?>) -> T? {
        let firstValue = sortedByKey.first?.value[keyPath: keyPath]
        guard let key = config else { return firstValue }
        let preferValue = self[key]?[keyPath: keyPath]
        return preferValue ?? firstValue
    }
}

extension Target {
    public func prefer<T>(_ keyPath: KeyPath<XCodeBuildSetting, T>) -> T? {
        config.prefer(config: project.preferConfig, keyPath)
    }

    // prevent T??
    public func prefer<T>(_ keyPath: KeyPath<XCodeBuildSetting, T?>) -> T? {
        config.prefer(config: project.preferConfig, keyPath)
    }
}
