//
//  Property+Operator.swift
//  
//
//  Created by Yume on 2022/8/3.
//

import Foundation

infix operator => : AssignmentPrecedence
extension String {
    static func =>(propertyName: String, @LabelBuilder builder: () -> [LabelBuilder.Target]) -> Property {
        .init(propertyName, builder: builder)
    }
    
    static func =>(propertyName: String, label: Label) -> Property {
        .init(propertyName, labels: [label])
    }
    
    static func =>(propertyName: String, labels: [Label]) -> Property {
        .init(propertyName, labels: labels)
    }
}
