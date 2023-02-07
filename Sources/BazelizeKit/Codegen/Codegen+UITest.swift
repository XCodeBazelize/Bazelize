//
//  UITest.swift
//
//
//  Created by Yume on 2023/1/7.
//

import Foundation
import RuleBuilder
import XCode

extension Target {
    // MARK: Internal

    func generateUITest(_ builder: CodeBuilder, _ kit: Kit) {
        switch prefer(\.sdk) {
        case .iOS: generateIOSUITest(builder, kit)
        case .macOS: generateMacUITest(builder, kit)
        case .tvOS: generateTVUITest(builder, kit)
        case .watchOS: generateWatchUITest(builder, kit)
        default: break
        }
    }

    // MARK: Private

    /// https://github.com/bazelbuild/rules_swift/blob/master/doc/rules.md#swift_test
    /// ios_unit_test(name, data, deps, env, platform_type, runner, test_filter, test_host)
    private func generateIOSUITest(_ builder: CodeBuilder, _: Kit) {
        builder.load(.ios_ui_test)
        builder.add(.ios_ui_test) {
            "name" => "\(name)"
            "test_host" => prefer(\.testTargetName).map { target in
                "//\(target):\(target)"
            }
            "minimum_os_version" => prefer(\.iOS)
            "deps" => {
                ":\(name)_library"
            }
            StarlarkProperty.Visibility.public
        }
    }

    /// https://github.com/bazelbuild/rules_apple/blob/2.0.0/doc/rules-macos.md#macos_ui_test
    /// macos_ui_test(name, data, deps, env, platform_type, runner, test_filter, test_host)
    private func generateMacUITest(_ builder: CodeBuilder, _: Kit) {
        builder.load(.macos_ui_test)
        builder.add(.macos_ui_test) {
            "name" => "\(name)"
            "test_host" => prefer(\.testTargetName).map { target in
                "//\(target):\(target)"
            }
            "minimum_os_version" => prefer(\.macOS)
            "deps" => {
                ":\(name)_library"
            }
            StarlarkProperty.Visibility.public
        }
    }

    /// https://github.com/bazelbuild/rules_apple/blob/master/doc/rules-tvos.md#tvos_ui_test
    /// tvos_ui_test(name, data, deps, env, platform_type, runner, test_filter, test_host)
    private func generateTVUITest(_ builder: CodeBuilder, _: Kit) {
        builder.load(.tvos_ui_test)
        builder.add(.tvos_ui_test) {
            "name" => "\(name)"
            "test_host" => prefer(\.testTargetName).map { target in
                "//\(target):\(target)"
            }
            "minimum_os_version" => prefer(\.tvOS)
            "deps" => {
                ":\(name)_library"
            }
            StarlarkProperty.Visibility.public
        }
    }

    /// https://github.com/bazelbuild/rules_apple/blob/master/doc/rules-watchos.md#watchos_ui_test
    /// watchos_ui_test(name, data, deps, env, platform_type, runner, test_filter, test_host)
    private func generateWatchUITest(_ builder: CodeBuilder, _: Kit) {
        builder.load(.watchos_ui_test)
        builder.add(.watchos_ui_test) {
            "name" => "\(name)"
            "test_host" => prefer(\.testTargetName).map { target in
                "//\(target):\(target)"
            }
            "minimum_os_version" => prefer(\.watchOS)
            "deps" => {
                ":\(name)_library"
            }
            StarlarkProperty.Visibility.public
        }
    }
}
