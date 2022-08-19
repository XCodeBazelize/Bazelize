//
//  Property.swift
//
//
//  Created by Yume on 2022/8/2.
//

import Foundation

// MARK: - Property

public struct StarlarkProperty: Text {
    // MARK: Lifecycle

    public init(_ name: String, starlark: Starlark) {
        self.name = name
        self.starlark = starlark
    }

    public init(_ name: String, @StarlarkBuilder builder: () -> Starlark) {
        self.init(name, starlark: builder())
    }

    // MARK: Public

    public let name: String
    public let starlark: Starlark


    public var text: String {
        switch starlark {
        case .comment:
            return "\(name) = None, \(starlark.text)"
        default:
            return "\(name) = \(starlark.text),"
        }
    }
}
