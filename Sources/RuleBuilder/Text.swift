//
//  BazelText.swift
//
//
//  Created by Yume on 2022/8/2.
//

import Foundation

// MARK: - Text

public protocol Text {
    var text: String { get }
}

// MARK: - CodeText

public protocol CodeText {
    var withComment: String { get }
    var withComma: String { get }
}
