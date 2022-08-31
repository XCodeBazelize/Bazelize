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
    func generateFrameworkCode(_ builder: inout Build.Builder, _ kit: Kit) {
        let depsXcode = ""
        builder.load(.ios_framework)
        generateSwiftLibrary(&builder, kit)

        builder.add(.ios_framework) {
            "name" => name
            "bundle_id" => prefer(\.bundleID)
            "families" => prefer(\.deviceFamily)
            "minimum_os_version" => prefer(\.iOS)
            "infoplists" => {
                plist_file
                plist_auto
                plist_default
            }
            "deps" => {
                ":\(name)_library"
            }
            "frameworks" => {
                depsXcode
            }
            StarlarkProperty.Visibility.public
        }
    }
}
