//
//  String+NewLine.swift
//  
//
//  Created by Yume on 2022/7/28.
//

import Foundation

extension Array where Element == String {
    public var withNewLine: String {
        self.joined(separator: "\n")
    }
}
