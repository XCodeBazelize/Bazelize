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
        return Property(propertyName, builder: builder)
    }
    
    public static func =>(propertyName: String, label: String?) -> Property {
        return Property(propertyName) {
            label
        }
    }
    
    public static func =>(propertyName: String, label: Label) -> Property {
        return Property(propertyName) {
            label
        }
    }
    
    public static func =>(propertyName: String, labels: [Label]) -> Property {
        return Property(propertyName) {
            labels
        }
    }
}
