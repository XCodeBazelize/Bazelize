//
//  LoadableRule.swift
//
//
//  Created by Yume on 2022/7/27.
//

import Foundation


// MARK: - BuildableRule

protocol BuildableRule {
    /// "ios_application"
    var rule: String { get }
}

// MARK: - LoadableRule

protocol LoadableRule: BuildableRule {
    /// "@build_bazel_rules_apple//apple:ios.bzl"
    static var target: String { get }

    /// load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application")
    var load: String { get }
}

extension BuildableRule where Self: RawRepresentable, Self.RawValue == String {
    var rule: String {
        rawValue
    }
}

extension LoadableRule {
    var load: String {
        """
        load("\(Self.target)", "\(rule)")
        """
    }
}
