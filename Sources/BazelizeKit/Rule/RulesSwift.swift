//
//  RulesSwift.swift
//
//
//  Created by Yume on 2022/7/1.
//

import Foundation

/// https://github.com/bazelbuild/rules_swift
enum RulesSwift: String, LoadableRule {
    static let target = "@build_bazel_rules_swift//swift:swift.bzl"

    case swift_binary
    case swift_c_module
    case swift_feature_allowlist
    case swift_grpc_library
    case swift_import
    case swift_library
    case swift_module_alias
    case swift_package_configuration
    case swift_proto_library
    case swift_test
}
