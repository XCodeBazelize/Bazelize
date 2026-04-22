//
//  Property.swift
//
//
//  Created by Yume on 2022/8/2.
//

import Foundation

// MARK: - Property

public struct StarlarkProperty: Text {
    public struct Comment: Text {
        public let value: String

        public init(_ value: String) {
            self.value = value
        }

        public var text: String {
            value.comment
        }
    }

    // MARK: Lifecycle

    public init(_ name: String, starlark: Starlark.Value) {
        self.name = name
        self.content = .starlark(starlark)
    }

    public init(_ name: String, comment: Comment) {
        self.name = name
        self.content = .comment(comment)
    }

    public init(_ name: String, @StarlarkBuilder builder: () -> Starlark.Value) {
        self.init(name, starlark: builder())
    }

    // MARK: Public

    public let name: String
    private let content: Content

    private enum Content {
        case starlark(Starlark.Value)
        case comment(Comment)
    }

    public var text: String {
        switch content {
        case let .comment(comment):
            return """
            \(comment.text)
            # \(name) = None,
            """
        case let .starlark(starlark):
            switch starlark {
            case .none:
                return """
                # \(name) = None,
                """
            default:
                return "\(name) = \(starlark.text),"
            }
        }
    }
}

extension StarlarkProperty {
    public static func comment(_ value: String) -> Comment {
        .init(value)
    }
}
