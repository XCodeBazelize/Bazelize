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
        .init(propertyName, builder: builder)
    }
    
    public static func =>(propertyName: String, label: Label) -> Property {
        .init(propertyName, labels: [label])
    }
    
    public static func =>(propertyName: String, labels: [Label]) -> Property {
        .init(propertyName, labels: labels)
    }
}
