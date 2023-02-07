//
//  Array+Extension.swift
//
//
//  Created by Yume on 2023/2/1.
//

import Foundation

extension Array {
    public func toDictionary<K: Hashable, V>() -> [K: V] where Element == (K, V) {
        return Dictionary(self, uniquingKeysWith: { first, _ in first })
    }
}
