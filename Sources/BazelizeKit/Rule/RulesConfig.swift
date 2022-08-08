//
//  RulesConfig.swift
//  
//
//  Created by Yume on 2022/8/5.
//

import Foundation

/// https://github.com/bazelbuild/bazel-skylib/blob/main/docs/common_settings_doc.md
enum RulesConfig: String, LoadableRule {
    static let target = "@bazel_skylib//rules:common_settings.bzl"
    
    case bool_flag
    case bool_setting
    
    case int_flag
    case int_setting
    
    case string_flag
    case string_setting
    
    case string_list_flag
    case string_list_setting
    
    case BuildSettingInfo
}
