//
//  Rules+Config.swift
//
//
//  Created by Yume on 2022/8/5.
//

import Foundation

/// https://github.com/bazelbuild/bazel-skylib/blob/main/docs/common_settings_doc.md
extension Rules {
    public enum Config: String, LoadableRule {
        public static let target = "@bazel_skylib//rules:common_settings.bzl"

    // MARK: - Bool

    case bool_flag
    case bool_setting

    // MARK: - Int

    case int_flag
    case int_setting

    // MARK: - String

    case string_flag
    case string_setting

    // MARK: - String List

    case string_list_flag
    case string_list_setting

    // MARK: - Provider

        case BuildSettingInfo
    }
}

@available(*, deprecated, renamed: "Rules.Config")
public typealias RulesConfig = Rules.Config
