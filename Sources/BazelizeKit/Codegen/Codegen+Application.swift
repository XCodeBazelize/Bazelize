//
//  Codegen+Application.swift
//
//
//  Created by Yume on 2022/4/29.
//

import Foundation
import XCode

//extension SDK {
//    fileprivate func load(_ builder: inout Build.Builder) {
//        switch self {
//        case .iOS: return builder.load(RulesApple.IOS.ios_application)
//        case .macOS: return builder.load(RulesApple.Mac.macos_application)
//        case .tvOS: return builder.load(RulesApple.TV.tvos_application)
//        case .watchOS: return builder.load(RulesApple.Watch.watchos_application)
//        default: break
//        }
//    }
//}

extension Target {
    func generateApplicationCode(_ kit: Kit) -> String {
        precondition(self.sdk != nil, "sdk")
        
        precondition(self.bundleID != nil, "bundle id")
        precondition(self.version != nil, "min version")
        
        #warning("todo infoPlist target")
        
        var builder = Build.Builder()
//        self.sdk?.load(&builder)
        builder.custom(generateSwiftLibrary(kit))
        
        switch self.sdk {
        case .iOS:      buildIOS(&builder)
        case .macOS:    buildMac(&builder)
        case .tvOS:     buildTV(&builder)
        case .watchOS:  buildWatch(&builder)
        default: break
        }

        return builder.build()
    }
    
    /// macos_command_line_application(name, additional_linker_inputs, bundle_id, codesign_inputs, codesignopts, deps, exported_symbols_lists, infoplists, launchdplists, linkopts, minimum_deployment_os_version, minimum_os_version, platform_type, provisioning_profile, stamp, version)
    func generateCommandLineApplicationCode(_ kit: Kit) -> String {
        precondition(self.bundleID != nil, "bundle id")
        precondition(self.version != nil, "min version")
        
        print(native.resourceFiles)
        
        var builder = Build.Builder()
        builder.load(.macos_command_line_application)
        builder.custom(generateSwiftLibrary(kit))
        
        builder.custom("""
        macos_command_line_application(
            name = "\(name)",
            bundle_id = "\(self.bundleID!)",
            minimum_os_version = "\(self.version!)",
            infoplists = [":Info.plist"],
            deps = [":_\(name)"],
            visibility = ["//visibility:public"],
        )
        """)
        
        return builder.build()
    }
    
    /// ios_application(name, additional_linker_inputs, alternate_icons, app_clips, app_icons, bundle_id, bundle_name, codesign_inputs, codesignopts, deps, entitlements, entitlements_validation, executable_name, exported_symbols_lists, extensions, families, frameworks, include_symbols_in_bundle, infoplists, ipa_post_processor, launch_images, launch_storyboard, linkopts, minimum_deployment_os_version, minimum_os_version, platform_type, provisioning_profile, resources, sdk_frameworks, settings_bundle, stamp, strings, version, watch_application)
    func buildIOS(_ builder: inout Build.Builder) {
        let depsXcode = ""
        let deviceFamily = self.deviceFamily?.joined(separator: "\n") ?? ""
        
        builder.load(.ios_application)
        builder.custom("""
        ios_application(
            name = "\(name)",
            bundle_id = "\(self.bundleID!)",
            families = [
        \(deviceFamily.indent(2))
            ],
            minimum_os_version = "\(self.version!)",
            infoplists = [":Info.plist"],
            launch_storyboard = ":Base.lproj/LaunchScreen.storyboard",
            deps = [":_\(name)"],
            frameworks = [
                # XCode Target Deps
        \(depsXcode)
            ],
            resources = [
        
            ],
            visibility = ["//visibility:public"],
        )
        """)
    }
    
    /// macos_application(name, additional_contents, additional_linker_inputs, app_icons, bundle_extension, bundle_id, bundle_name, codesign_inputs, codesignopts, deps, entitlements, entitlements_validation, executable_name, exported_symbols_lists, extensions, include_symbols_in_bundle, infoplists, ipa_post_processor, linkopts, minimum_deployment_os_version, minimum_os_version, platform_type, provisioning_profile, resources, stamp, strings, version, xpc_services)
    func buildMac(_ builder: inout Build.Builder) {
        let depsXcode = ""
        
        builder.load(.macos_application)
        builder.custom("""
        macos_application(
            name = "\(name)",
            bundle_id = "\(self.bundleID!)",
            minimum_os_version = "\(self.version!)",
            infoplists = [":Info.plist"],
            deps = [":_\(name)"],
            frameworks = [
                # XCode Target Deps
        \(depsXcode)
            ],
            resources = [
        
            ],
            visibility = ["//visibility:public"],
        )
        """)
    }
    
    /// tvos_application(name, additional_linker_inputs, app_icons, bundle_id, bundle_name, codesign_inputs, codesignopts, deps, entitlements, entitlements_validation, executable_name, exported_symbols_lists, extensions, frameworks, infoplists, ipa_post_processor, launch_images, linkopts, minimum_deployment_os_version, minimum_os_version, platform_type, provisioning_profile, resources, settings_bundle, stamp, strings, version)
    func buildTV(_ builder: inout Build.Builder) {
        builder.load(.tvos_application)
        builder.custom("""
        tvos_application(
            name = "\(name)",
            bundle_id = "\(self.bundleID!)",
            minimum_os_version = "\(self.version!)",
            infoplists = [":Info.plist"],
            deps = [":_\(name)"],
            frameworks = [
                # XCode Target Deps
        
            ],
            resources = [
        
            ],
            visibility = ["//visibility:public"],
        )
        """)
    }
    
    /// watchos_application(name, app_icons, bundle_id, bundle_name, deps, entitlements, entitlements_validation, executable_name, extension, infoplists, ipa_post_processor, minimum_deployment_os_version, minimum_os_version, platform_type, provisioning_profile, resources, storyboards, strings, version)
    func buildWatch(_ builder: inout Build.Builder) {
        builder.load(.watchos_application)
        builder.custom("""
        watchos_application(
            name = "\(name)",
            bundle_id = "\(self.bundleID!)",
            minimum_os_version = "\(self.version!)",
            infoplists = [":Info.plist"],
            deps = [":_\(name)"],
            frameworks = [
                # XCode Target Deps
        
            ],
            resources = [
        
            ],
            visibility = ["//visibility:public"],
        )
        """)
    }
}
