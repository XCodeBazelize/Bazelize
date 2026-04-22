//
//  Rules+Swift.swift
//
//
//  Created by Yume on 2022/7/1.
//

import Foundation

/// https://github.com/bazelbuild/rules_swift
extension Rules {
    public enum Swift: String, LoadableRule {
        public static let target = "@build_bazel_rules_swift//swift:swift.bzl"

    // MARK: - Swift Rules

    case swift_library
    case swift_binary
    case swift_test

    // MARK: - Interop / Import

    case swift_import
    case swift_c_module
    case swift_module_alias

    // MARK: - Tooling / Generation

    case swift_feature_allowlist
    case swift_grpc_library
        case swift_package_configuration
        case swift_proto_library
    }
}

@available(*, deprecated, renamed: "Rules.Swift")
public typealias RulesSwift = Rules.Swift
