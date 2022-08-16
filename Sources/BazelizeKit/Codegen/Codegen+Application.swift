//
//  Codegen+Application.swift
//
//
//  Created by Yume on 2022/4/29.
//

import Foundation
import PluginInterface
import XCode
import RuleBuilder

extension Target {
    // TODO: https://github.com/XCodeBazelize/Bazelize/issues/3
    var setting: XCodeBuildSetting { self["Release"]! }


    func generateApplicationCode(_ kit: Kit) -> String {
        precondition(setting.sdk != nil, "sdk")

        precondition(setting.bundleID != nil, "bundle id")

        var builder = Build.Builder()
        builder.custom(generateSwiftLibrary(kit))

        switch setting.sdk {
        case .iOS: buildIOS(&builder)
        case .macOS: buildMac(&builder)
        case .tvOS: buildTV(&builder)
        case .watchOS: buildWatch(&builder)
        default: break
        }

        return builder.build()
    }

    /// macos_command_line_application(name, additional_linker_inputs, bundle_id, codesign_inputs, codesignopts, deps, exported_symbols_lists, infoplists, launchdplists, linkopts, minimum_deployment_os_version, minimum_os_version, platform_type, provisioning_profile, stamp, version)
    func generateCommandLineApplicationCode(_ kit: Kit) -> String {
        precondition(setting.macOS != nil, "min version")

        var builder = Build.Builder()
        builder.load(.macos_command_line_application)
        builder.custom(generateSwiftLibrary(kit))

        builder.add(.macos_command_line_application) {
            "name" => name
            "bundle_id" => setting.bundleID
            "minimum_os_version" => setting.macOS
            "infoplists" => setting.infoPlist
            "deps" => ":\(name)_library"
            StarlarkProperty.Visibility.public
        }

        return builder.build()
    }

    /// ios_application(name, additional_linker_inputs, alternate_icons, app_clips, app_icons, bundle_id, bundle_name, codesign_inputs, codesignopts, deps, entitlements, entitlements_validation, executable_name, exported_symbols_lists, extensions, families, frameworks, include_symbols_in_bundle, infoplists, ipa_post_processor, launch_images, launch_storyboard, linkopts, minimum_deployment_os_version, minimum_os_version, platform_type, provisioning_profile, resources, sdk_frameworks, settings_bundle, stamp, strings, version, watch_application)
    func buildIOS(_ builder: inout Build.Builder) {
        builder.load(.ios_application)
        builder.add(.ios_application) {
            "name" => name
            "bundle_id" => setting.bundleID
            "families" => setting.deviceFamily
            "minimum_os_version" => setting.iOS
            "infoplists" => setting.infoPlist
            "launch_storyboard" => ":Base.lproj/LaunchScreen.storyboard"
            "deps" => ":\(name)_library"
            "frameworks" => frameworks
            "sdk_frameworks" => sdkFrameworks
            "resources" => resources
            StarlarkProperty.Visibility.public
        }
    }

    /// macos_application(name, additional_contents, additional_linker_inputs, app_icons, bundle_extension, bundle_id, bundle_name, codesign_inputs, codesignopts, deps, entitlements, entitlements_validation, executable_name, exported_symbols_lists, extensions, include_symbols_in_bundle, infoplists, ipa_post_processor, linkopts, minimum_deployment_os_version, minimum_os_version, platform_type, provisioning_profile, resources, stamp, strings, version, xpc_services)
    func buildMac(_ builder: inout Build.Builder) {
        builder.load(.macos_application)
        
        builder.add(.macos_application) {
            "name" => name
            "bundle_id" => setting.bundleID
//            "families" => setting.deviceFamily
            "minimum_os_version" => setting.macOS
            "infoplists" => setting.infoPlist
//            "launch_storyboard" => ":Base.lproj/LaunchScreen.storyboard"
            "deps" => ":\(name)_library"
//            "frameworks" => frameworks
//            "sdk_frameworks" => sdkFrameworks
//            "resources" => resources
            StarlarkProperty.Visibility.public
        }
    }

    /// tvos_application(name, additional_linker_inputs, app_icons, bundle_id, bundle_name, codesign_inputs, codesignopts, deps, entitlements, entitlements_validation, executable_name, exported_symbols_lists, extensions, frameworks, infoplists, ipa_post_processor, launch_images, linkopts, minimum_deployment_os_version, minimum_os_version, platform_type, provisioning_profile, resources, settings_bundle, stamp, strings, version)
    func buildTV(_ builder: inout Build.Builder) {
        builder.load(.tvos_application)
        builder.add(.tvos_application) {
            "name" => name
            "bundle_id" => setting.bundleID
            "minimum_os_version" => setting.tvOS
            "infoplists" => setting.infoPlist
            "deps" => ":\(name)_library"
            "frameworks" => frameworks
            "resources" => resources
            StarlarkProperty.Visibility.public
        }
    }

    /// watchos_application(name, app_icons, bundle_id, bundle_name, deps, entitlements, entitlements_validation, executable_name, extension, infoplists, ipa_post_processor, minimum_deployment_os_version, minimum_os_version, platform_type, provisioning_profile, resources, storyboards, strings, version)
    func buildWatch(_ builder: inout Build.Builder) {
        builder.load(.watchos_application)
        builder.add(.watchos_application) {
            "name" => name
            "bundle_id" => setting.bundleID
            "minimum_os_version" => setting.watchOS
            "infoplists" => setting.infoPlist
            "deps" => ":\(name)_library"
            "frameworks" => frameworks
            "resources" => resources
            StarlarkProperty.Visibility.public
        }
    }
}
