//
//  Property+Operator.swift
//
//
//  Created by Yume on 2022/8/3.
//

import Foundation

infix operator => : AssignmentPrecedence
extension String {
    public static func =>(propertyName: String, @LabelBuilder builder: () -> [LabelBuilder.Target]) -> StarlarkProperty {
        StarlarkProperty(propertyName, builder: builder)
    }

    public static func =>(propertyName: String, label: String?) -> StarlarkProperty {
        StarlarkProperty(propertyName) {
            label
        }
    }

    public static func =>(propertyName: String, dictionary: [String: String]) -> StarlarkProperty {
        StarlarkProperty(propertyName) {
            StarlarkDictionary(dictionary)
        }
    }

    public static func =>(propertyName: String, label: StarlarkLabel) -> StarlarkProperty {
        StarlarkProperty(propertyName) {
            label
        }
    }

    public static func =>(propertyName: String, labels: [StarlarkLabel]) -> StarlarkProperty {
        StarlarkProperty(propertyName) {
            labels
        }
    }
}
