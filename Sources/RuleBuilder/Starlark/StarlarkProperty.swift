//
//  Property.swift
//
//
//  Created by Yume on 2022/8/2.
//

import Foundation

// MARK: - Property

public struct StarlarkProperty: Text {
    // MARK: Lifecycle

    public init(_ name: String, labels: [LabelBuilder.Target]) {
        self.name = name
        self.labels = labels
    }

    public init(_ name: String, @LabelBuilder builder: () -> [LabelBuilder.Target]) {
        self.init(name, labels: builder())
    }

    // MARK: Public

    public let name: String
    public let labels: [LabelBuilder.Target]


    public var text: String {
        switch labels.count {
        case 0:
            return "\(name) = None,"
        case 1 where labels[0] is StarlarkComment:
            return "\(name) = None, \(labels[0].text)"
        case 1 where labels[0] is StarlarkLabel: fallthrough
        case 1 where labels[0] is StarlarkDictionary:
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
