//
//  Rules+Apple.swift
//
//
//  Created by Yume on 2022/7/1.
//

import Foundation
import RuleBuilder

/// https://github.com/bazelbuild/rules_apple/tree/master/doc
extension Rules {
    public enum Apple {
        // MARK: - Platform Rules
        
        public enum IOS: String, LoadableRule {
            public static let target = "@build_bazel_rules_apple//apple:ios.bzl"
            
            case ios_application
            case ios_app_clip
            case ios_extension
            case ios_imessage_application
            case ios_imessage_extension
            case ios_sticker_pack_extension
            case ios_framework
            case ios_static_framework
            case ios_dynamic_framework
            
            case ios_ui_test
            case ios_ui_test_suite
            case ios_unit_test
            case ios_unit_test_suite
            case ios_build_test
            
            
        }
        
        public enum MacOS: String, LoadableRule {
            public static let target = "@build_bazel_rules_apple//apple:macos.bzl"
            
            case macos_application
            case macos_bundle
            case macos_command_line_application
            case macos_extension
            
            case macos_ui_test
            case macos_unit_test
            case macos_build_test
            
            case macos_dylib
            case macos_kernel_extension
            case macos_quick_look_plugin
            case macos_spotlight_importer
            case macos_xpc_service
        }
        
        public enum TVOS: String, LoadableRule {
            public static let target = "@build_bazel_rules_apple//apple:tvos.bzl"
            
            case tvos_application
            case tvos_extension
            case tvos_static_framework
            case tvos_dynamic_framework
            case tvos_ui_test
            case tvos_unit_test
            case tvos_build_test
        }
        
        public enum WatchOS: String, LoadableRule {
            public static let target = "@build_bazel_rules_apple//apple:watchos.bzl"
            
            case watchos_application
            case watchos_extension
            case watchos_static_framework
            case watchos_dynamic_framework
            case watchos_ui_test
            case watchos_unit_test
            case watchos_build_test
        }
        
        // MARK: - Shared Apple Rules
        
        public enum General: String, LoadableRule {
            public static let target = "@build_bazel_rules_apple//apple:apple.bzl"
            
            case apple_dynamic_framework_import
            case apple_dynamic_xcframework_import
            case apple_static_framework_import
            case apple_static_library
            case apple_static_xcframework
            case apple_static_xcframework_import
            case apple_universal_binary
            case apple_xcframework
            case local_provisioning_profile
            case provisioning_profile_repository
            case provisioning_profile_repository_extension
        }
        
        public enum Resources: String, LoadableRule {
            public static let target = "@build_bazel_rules_apple//apple:resources.bzl"
            
            case apple_bundle_import
            case apple_core_data_model
            case apple_core_ml_library
            case apple_resource_bundle
            case apple_resource_group
            case swift_apple_core_ml_library
            case swift_intent_library
        }
        
        public enum Versioning: String, LoadableRule {
            public static let target = "@build_bazel_rules_apple//apple:versioning.bzl"
            
            case apple_bundle_version
        }
        
        public enum Packaging: String, LoadableRule {
            public static let target = "@build_bazel_rules_apple//apple:packaging.bzl"
            
            case xcarchive
            case xctrunner
        }
    }
}

@available(*, deprecated, renamed: "Rules.Apple")
public typealias RulesApple = Rules.Apple

extension Rules.Apple.IOS {
    enum Action {
//        static func ios_application() -> Starlark.Statement {
//            
////            builder.add(.ios_application) {
////                "name" => name
////                "bundle_id" => prefer(\.bundleID)
////            }
//            return .call(<#T##Starlark.Statement.Call#>)
//        }
    }
}
