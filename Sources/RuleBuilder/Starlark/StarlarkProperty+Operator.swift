//  Property+Operator.swift
//
//
//  Created by Yume on 2022/8/3.
//

import Foundation

infix operator => : AssignmentPrecedence
extension String {
    public static func =>(propertyName: String, @StarlarkBuilder builder: () -> Starlark) -> StarlarkProperty {
        StarlarkProperty(propertyName, builder: builder)
    }

    public static func =>(propertyName: String, bool: Bool) -> StarlarkProperty {
        StarlarkProperty(propertyName) {
            bool
        }
    }

    public static func =>(propertyName: String, label: String?) -> StarlarkProperty {
        StarlarkProperty(propertyName) {
            label
        }
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

    public static func =>(propertyName: String, dictionary: [String: String]) -> StarlarkProperty {
        StarlarkProperty(propertyName) {
            dictionary
        }
    }

    public static func =>(propertyName: String, starlark: Starlark) -> StarlarkProperty {
        StarlarkProperty(propertyName) {
            starlark
        }
    }

    public static func =>(propertyName: String, starlarks: [Starlark]) -> StarlarkProperty {
        StarlarkProperty(propertyName) {
            starlarks
        }
    }
}
