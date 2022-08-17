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

    public static func =>(propertyName: String, bool: Bool) -> StarlarkProperty {
        StarlarkProperty(propertyName) {
            StarlarkBool(bool)
        }
    }

    public static func =>(propertyName: String, label: String?) -> StarlarkProperty {
        StarlarkProperty(propertyName) {
            label
        }
    }

    public static func =>(propertyName: String, labels: [String]) -> StarlarkProperty {
        StarlarkProperty(propertyName) {
            labels.map(StarlarkLabel.init(stringLiteral:))
        }
    }

    public static func =>(propertyName: String, dictionary: [String: String]) -> StarlarkProperty {
        StarlarkProperty(propertyName) {
            StarlarkDictionary(dictionary)
        }
    }

    public static func =>(propertyName: String, target: LabelBuilder.Target) -> StarlarkProperty {
        StarlarkProperty(propertyName) {
            target
        }
    }

    public static func =>(propertyName: String, targets: [LabelBuilder.Target]) -> StarlarkProperty {
        StarlarkProperty(propertyName) {
            targets
        }
    }
}
