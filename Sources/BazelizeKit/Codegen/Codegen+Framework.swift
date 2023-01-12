//
//  Codegen+Framework.swift
//
//
//  Created by Yume on 2022/4/29.
//

import Foundation
import RuleBuilder
import XCode

// TODO: https://github.com/XCodeBazelize/Bazelize/issues/8 framework(static/dynamic)

extension Target {
    /// ios_framework(name, additional_linker_inputs, bundle_id, bundle_name, bundle_only, codesign_inputs, codesignopts, deps, executable_name, exported_symbols_lists, extension_safe, families, frameworks, hdrs, infoplists, ipa_post_processor, linkopts, minimum_deployment_os_version, minimum_os_version, platform_type, provisioning_profile, resources, stamp, strings, version)
    /// Builds and bundles an iOS Dynamic Framework.
    ///
    /// To use this framework for your app and extensions, list it in the frameworks attributes of those ios_application and/or ios_extension rules.
    func generateFrameworkCode(_ builder: inout Build.Builder, _: Kit) {
        builder.load(.ios_framework)
        builder.add(.ios_framework) {
            "name" => name
            "bundle_id" => prefer(\.bundleID)
            "families" => prefer(\.deviceFamily)
            "minimum_os_version" => prefer(\.iOS)
            "infoplists" => {
                plist_file
                plist_auto
//                plist_default
            }
            "deps" => {
                ":\(name)_library"
                frameworks
            }
            StarlarkProperty.Visibility.public
        }
    }
}
