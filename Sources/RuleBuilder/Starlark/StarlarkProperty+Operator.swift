//  Property+Operator.swift
//
//
//  Created by Yume on 2022/8/3.
//

import Foundation

infix operator => : AssignmentPrecedence
extension String {
    public static func =>(propertyName: String, bool: Bool) -> StarlarkProperty {
        StarlarkProperty(propertyName, starlark: .bool(bool))
    }

    public static func =>(propertyName: String, label: String?) -> StarlarkProperty {
        StarlarkProperty(propertyName, starlark: .init(label) ?? None)
    }

    public static func =>(propertyName: String, dictionary: [String: String]) -> StarlarkProperty {
        StarlarkProperty(propertyName, starlark: .init(dictionary) ?? None)
    }

    public static func =>(propertyName: String, starlark: Starlark.Value) -> StarlarkProperty {
        StarlarkProperty(propertyName, starlark: starlark)
    }

    public static func =>(propertyName: String, comment: StarlarkProperty.Comment) -> StarlarkProperty {
        StarlarkProperty(propertyName, comment: comment)
    }
}

extension String {
    public static func =>(propertyName: String, @StarlarkBuilder builder: () -> Starlark.Value) -> StarlarkProperty {
        StarlarkProperty(propertyName, builder: builder)
    }

    public static func =>(propertyName: String, labels: [String]) -> StarlarkProperty {
        StarlarkProperty(propertyName) {
            labels
        }
    }

    public static func =>(propertyName: String, labels: [String]?) -> StarlarkProperty {
        StarlarkProperty(propertyName) {
            labels
        }
    }

    public static func =>(propertyName: String, starlarks: [Starlark.Value]) -> StarlarkProperty {
        StarlarkProperty(propertyName) {
            starlarks
        }
    }
}
