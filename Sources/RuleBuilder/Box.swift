//
//  Box.swift
//
//
//  Created by Yume on 2022/8/16.
//

import Foundation

@frozen
public indirect enum Box<T> {
    case single(T)
    case multi([T])
    case nothing
    case nest([Box<T>])

    var flat: [T] {
        switch self {
        case .nothing:
            return []
        case .single(let t):
            return [t]
        case .multi(let ts):
            return ts
        case .nest(let nest):
            return nest.flatMap {
                $0.flat
            }
        }
    }
}
