//
//  Rules+Objc.swift
//
//
//  Created by Yume on 2022/7/22.
//

import Foundation

/// https://bazel.build/reference/be/objective-c
extension Rules {
    public enum Objc: String, LoadableRule {
        public static let target = "@rules_cc//cc:defs.bzl"

    // MARK: - Objective-C Rules

    case objc_library
    case objc_import
    case j2objc_library

    // MARK: - Xcode Configuration

    case available_xcodes
        case xcode_config
        case xcode_version
    }
}

@available(*, deprecated, renamed: "Rules.Objc")
public typealias RulesObjc = Rules.Objc
