//
//  Target+Select.swift
//
//
//  Created by Yume on 2022/8/17.
//

import Foundation
import RuleBuilder
import XcodeProj

extension Dictionary where Key == String {
    // MARK: Public

    public func select<T: Hashable>(_ keypath: KeyPath<Value, T>) -> Starlark.Select<T> {
        if checkSame(keypath) {
            return selectSame(keypath)
        }
        return selectVarious(keypath)
    }

    // MARK: Private

    private func checkSame<T: Hashable>(_ keypath: KeyPath<Value, T>) -> Bool {
        let values: [T] = map { _, setting in
            setting[keyPath: keypath]
        }

        return Set<T>(values).count == 1
    }

    private func selectSame<T>(_ keypath: KeyPath<Value, T>) -> Starlark.Select<T> {
        guard let value = first?.value[keyPath: keypath] else {
            return selectVarious(keypath)
        }
        return .same(value)
    }

    private func selectVarious<T>(_ keypath: KeyPath<Value, T>) -> Starlark.Select<T> {
        let result: [Starlark.Label: T] = reduce(into: [:]) { partialResult, entry in
            partialResult[.config(entry.key)] = entry.value[keyPath: keypath]
        }
        return .various(result)
    }
}

extension Target {
    public func select<T: Hashable>(_ keypath: KeyPath<BuildSettings, T>) -> Starlark.Select<T> {
        config.select(keypath)
    }
}
