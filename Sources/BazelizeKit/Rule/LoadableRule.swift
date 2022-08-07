//
//  LoadableRule.swift
//  
//
//  Created by Yume on 2022/7/27.
//

import Foundation

protocol LoadableRule {
    /// "@build_bazel_rules_apple//apple:ios.bzl"
    static var target: String {get}
    
    /// "ios_application"
    var rule: String {get}
    
    /// load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application")
    var load: String {get}
}

extension LoadableRule where Self: RawRepresentable, Self.RawValue == String {
    var rule: String {
        rawValue
    }
}

extension LoadableRule {
    var load: String {
        return """
        load("\(Self.target)", "\(rule)")
        """
    }
}
