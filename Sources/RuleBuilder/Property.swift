//
//  Property.swift
//
//
//  Created by Yume on 2022/8/2.
//

import Foundation

public struct Property: Text {
    public let name: String
    public let labels: [LabelBuilder.Target]
    
    public init(_ name: String, labels: [LabelBuilder.Target]) {
        self.name = name
        self.labels = labels
    }
    
    public init(_ name: String, @LabelBuilder builder: () -> [LabelBuilder.Target]) {
        self.init(name, labels: builder())
    }
    
    public var text: String {
        switch labels.count {
        case 0:
            return "\(name) = None,"
        case 1 where labels[0] is Comment:
            return "\(name) = None, \(labels[0].text)"
        case 1 where labels[0] is Label:
            return "\(name) = \(labels[0].text),"
        default:
            return """
            \(name) = [
            \(labels.map(\.withComma).withNewLine.indent(1))
            ],
            """
        }
    }
}
