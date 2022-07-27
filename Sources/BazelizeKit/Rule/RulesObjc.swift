//
//  RulesObjc.swift
//  
//
//  Created by Yume on 2022/7/22.
//

import Foundation

/// https://bazel.build/reference/be/objective-c
enum RulesObjc: String, LoadableRule {
    static let target = "@rules_cc//cc:defs.bzl"
    
    case j2objc_library
    case objc_import
    case objc_library
    case available_xcodes
    case xcode_config
    case xcode_version
}
