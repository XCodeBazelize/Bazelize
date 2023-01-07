//
//  UnitTest.swift
//
//
//  Created by Yume on 2022/4/29.
//

import Foundation
import RuleBuilder
import XCode

extension Target {
    // MARK: Internal

    func generateUnitTest(_ builder: inout Build.Builder, _ kit: Kit) {
        switch prefer(\.sdk) {
        case .iOS: generateIOSUnitTest(&builder, kit)
        case .macOS: generateMacUnitTest(&builder, kit)
        case .tvOS: generateTVUnitTest(&builder, kit)
        case .watchOS: generateWatchUnitTest(&builder, kit)
        default: break
        }
    }

    // MARK: Private

    /// https://github.com/bazelbuild/rules_swift/blob/master/doc/rules.md#swift_test
    /// ios_unit_test(name, data, deps, env, platform_type, runner, test_filter, test_host)
    private func generateIOSUnitTest(_ builder: inout Build.Builder, _: Kit) {
        builder.load(.ios_unit_test)
        builder.add(.ios_unit_test) {
            "name" => "\(name)"
            "minimum_os_version" => prefer(\.iOS)
            "deps" => {
                ":\(name)_library"
            }
            StarlarkProperty.Visibility.public
        }
    }

    /// https://github.com/bazelbuild/rules_apple/blob/2.0.0/doc/rules-macos.md#macos_unit_test
    /// macos_unit_test(name, data, deps, env, platform_type, runner, test_filter, test_host)
    private func generateMacUnitTest(_ builder: inout Build.Builder, _: Kit) {
        builder.load(.macos_unit_test)
        builder.add(.macos_unit_test) {
            "name" => "\(name)"
            "minimum_os_version" => prefer(\.macOS)
            "deps" => {
                ":\(name)_library"
            }
            StarlarkProperty.Visibility.public
        }
    }

    /// https://github.com/bazelbuild/rules_apple/blob/master/doc/rules-tvos.md#tvos_unit_test
    /// tvos_unit_test(name, data, deps, env, platform_type, runner, test_filter, test_host)
    private func generateTVUnitTest(_ builder: inout Build.Builder, _: Kit) {
        builder.load(.tvos_unit_test)
        builder.add(.tvos_unit_test) {
            "name" => "\(name)"
            "minimum_os_version" => prefer(\.tvOS)
            "deps" => {
                ":\(name)_library"
            }
            StarlarkProperty.Visibility.public
        }
    }

    /// https://github.com/bazelbuild/rules_apple/blob/master/doc/rules-watchos.md#watchos_unit_test
    /// watchos_unit_test(name, data, deps, env, platform_type, runner, test_filter, test_host)
    private func generateWatchUnitTest(_ builder: inout Build.Builder, _: Kit) {
        builder.load(.watchos_unit_test)
        builder.add(.watchos_unit_test) {
            "name" => "\(name)"
            "minimum_os_version" => prefer(\.watchOS)
            "deps" => {
                ":\(name)_library"
            }
            StarlarkProperty.Visibility.public
        }
    }
}

