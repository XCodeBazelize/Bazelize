//
//  Target+Select.swift
//
//
//  Created by Yume on 2022/8/17.
//

import AnyCodable
import Foundation
import PluginInterface
import RuleBuilder
import XcodeProj

extension Target {
    public func preffer<T>(config: String = "Release", _ keypath: KeyPath<XCodeBuildSetting, T>) -> T? {
        let prefferValue = self.config[config]?[keyPath: keypath]
        let firstValue = self.config.sorted { lhs, rhs in
            lhs.key < rhs.key
        }.first?.value[keyPath: keypath]
        return prefferValue ?? firstValue
    }

    // prevent T??
    public func preffer<T>(config: String = "Release", _ keypath: KeyPath<XCodeBuildSetting, T?>) -> T? {
        let prefferValue = self.config[config]?[keyPath: keypath]
        let firstValue = self.config.sorted { lhs, rhs in
            lhs.key < rhs.key
        }.first?.value[keyPath: keypath]
        return prefferValue ?? firstValue
    }
}

extension Target {
    // MARK: Public

    public func select<T: Hashable>(_ keypath: KeyPath<XCodeBuildSetting, T>) -> Starlark.Select<T> {
        if checkSame(keypath) {
            return selectSame(keypath)
        }
        return selectVarious(keypath)
    }

    // MARK: Private

    private func checkSame<T: Hashable>(_ keypath: KeyPath<XCodeBuildSetting, T>) -> Bool {
        let values: [T] = config.map { _, setting in
            setting[keyPath: keypath]
        }

        return Set<T>(values).count == 1
    }

    private func selectSame<T>(_ keypath: KeyPath<XCodeBuildSetting, T>) -> Starlark.Select<T> {
        guard let value = config.first?.value[keyPath: keypath] else {
            return selectVarious(keypath)
        }
        return .same(value)
    }

    private func selectVarious<T>(_ keypath: KeyPath<XCodeBuildSetting, T>) -> Starlark.Select<T> {
        let result = config.mapValues { setting in
            setting[keyPath: keypath]
        }
        return .various(result)
    }
}
