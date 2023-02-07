//
//  Codegen+Application.swift
//
//
//  Created by Yume on 2022/4/29.
//

import Foundation
import PathKit
import PluginInterface
import RuleBuilder
import XCode

extension Target {
    // MARK: Internal

    func generateApplicationCode(_ builder: CodeBuilder, _ kit: Kit) {
        switch prefer(\.sdk) {
        case .iOS: buildIOS(builder, kit)
        case .macOS: buildMac(builder, kit)
        case .tvOS: buildTV(builder, kit)
        case .watchOS: buildWatch(builder, kit)
        default: break
        }
    }

    /// macos_command_line_application(name, additional_linker_inputs, bundle_id, codesign_inputs, codesignopts, deps, exported_symbols_lists, infoplists, launchdplists, linkopts, minimum_deployment_os_version, minimum_os_version, platform_type, provisioning_profile, stamp, version)
    func generateCommandLineApplicationCode(_ builder: CodeBuilder, _: Kit) {
        builder.load(.macos_command_line_application)
        builder.add(.macos_command_line_application) {
            "name" => name
            "bundle_id" => prefer(\.bundleID)
            "minimum_os_version" => prefer(\.macOS)
            "infoplists" => {
                plist_file
                plist_auto
                // plist_default
            }
            "deps" => {
                ":\(name)_library"
            }
            StarlarkProperty.Visibility.public
        }
    }

    // MARK: Private

    /// watchos_application(name, app_icons, bundle_id, bundle_name, deps, entitlements, entitlements_validation, executable_name, extension, infoplists, ipa_post_processor, minimum_deployment_os_version, minimum_os_version, platform_type, provisioning_profile, resources, storyboards, strings, version)
    private func buildWatch(_ builder: CodeBuilder, _: Kit) {
        builder.load(.watchos_application)
        builder.add(.watchos_application) {
            "name" => name
            "bundle_id" => prefer(\.bundleID)
            "minimum_os_version" => prefer(\.watchOS)
            "infoplists" => {
                plist_file
                plist_auto
                plist_default
            }
            "deps" => {
                ":\(name)_library"
                frameworks
            }
            "resources" => {
                resources
            }
            StarlarkProperty.Visibility.public
        }
    }

    /// ios_application(name, additional_linker_inputs, alternate_icons, app_clips, app_icons, bundle_id, bundle_name, codesign_inputs, codesignopts, deps, entitlements, entitlements_validation, executable_name, exported_symbols_lists, extensions, families, frameworks, include_symbols_in_bundle, infoplists, ipa_post_processor, launch_images, launch_storyboard, linkopts, minimum_deployment_os_version, minimum_os_version, platform_type, provisioning_profile, resources, sdk_frameworks, settings_bundle, stamp, strings, version, watch_application)
    private func buildIOS(_ builder: CodeBuilder, _: Kit) {
        builder.load(.ios_application)
        builder.add(.ios_application) {
            "name" => name
            "bundle_id" => prefer(\.bundleID)
            "families" => prefer(\.deviceFamily)
            "minimum_os_version" => prefer(\.iOS)
            "infoplists" => {
                plist_file
                plist_auto
                plist_default
            }
            // "launch_storyboard" => ":Base.lproj/LaunchScreen.storyboard"
            "deps" => {
                ":\(name)_library"
                frameworks
            }
            "sdk_frameworks" => {
                frameworksSDK
            }
            "strings" => {
                if !allStrings.isEmpty {
                    ":Strings"
                }
            }
            StarlarkProperty.Visibility.public
        }
    }

    /// macos_application(name, additional_contents, additional_linker_inputs, app_icons, bundle_extension, bundle_id, bundle_name, codesign_inputs, codesignopts, deps, entitlements, entitlements_validation, executable_name, exported_symbols_lists, extensions, include_symbols_in_bundle, infoplists, ipa_post_processor, linkopts, minimum_deployment_os_version, minimum_os_version, platform_type, provisioning_profile, resources, stamp, strings, version, xpc_services)
    private func buildMac(_ builder: CodeBuilder, _: Kit) {
        builder.load(.macos_application)

        builder.add(.macos_application) {
            "name" => name
            "bundle_id" => prefer(\.bundleID)
            "minimum_os_version" => prefer(\.macOS)
            "infoplists" => {
                plist_file
                plist_auto
                plist_default
            }
            "deps" => {
                ":\(name)_library"
            }
            StarlarkProperty.Visibility.public
        }
    }

    /// tvos_application(name, additional_linker_inputs, app_icons, bundle_id, bundle_name, codesign_inputs, codesignopts, deps, entitlements, entitlements_validation, executable_name, exported_symbols_lists, extensions, frameworks, infoplists, ipa_post_processor, launch_images, linkopts, minimum_deployment_os_version, minimum_os_version, platform_type, provisioning_profile, resources, settings_bundle, stamp, strings, version)
    private func buildTV(_ builder: CodeBuilder, _: Kit) {
        builder.load(.tvos_application)
        builder.add(.tvos_application) {
            "name" => name
            "bundle_id" => prefer(\.bundleID)
            "minimum_os_version" => prefer(\.tvOS)
            "infoplists" => {
                plist_file
                plist_auto
                plist_default
            }
            "deps" => {
                ":\(name)_library"
                frameworks
            }
            "resources" => {
                resources
            }
            StarlarkProperty.Visibility.public
        }
    }
}
