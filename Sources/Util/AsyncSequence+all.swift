//
//  AsyncSequence+all.swift
//  
//
//  Created by Yume on 2022/7/1.
//

import Foundation

extension AsyncSequence {
    public var all: [Element] {
        get async throws {
            var iterator = makeAsyncIterator()
            var result: [Element] = []
            while let next = try await iterator.next() {
                result.append(next)
            }
            return result
        }
    }
}
