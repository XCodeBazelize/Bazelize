//
//  Property+Operator.swift
//
//
//  Created by Yume on 2022/8/3.
//

import Foundation

infix operator => : AssignmentPrecedence
extension String {
    public static func =>(propertyName: String, @LabelBuilder builder: () -> [LabelBuilder.Target]) -> Property {
        Property(propertyName, builder: builder)
    }

    public static func =>(propertyName: String, label: String?) -> Property {
        Property(propertyName) {
            label
        }
    }

    public static func =>(propertyName: String, dictionary: [String: String]) -> Property {
        Property(propertyName) {
            Dictionary(dictionary)
        }
    }

    public static func =>(propertyName: String, label: Label) -> Property {
        Property(propertyName) {
            label
        }
    }

    public static func =>(propertyName: String, labels: [Label]) -> Property {
        Property(propertyName) {
            labels
        }
    }
}
