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
    func generateFrameworkCode(_ kit: Kit) -> String {
        let depsXcode = ""

        var builder = Build.Builder()
        builder.load(.ios_framework)
        builder.custom(generateSwiftLibrary(kit))

        builder.add(.ios_framework) {
            "name" => name
            "bundle_id" => prefer(\.bundleID)
            "families" => prefer(\.deviceFamily)
            "minimum_os_version" => prefer(\.iOS)
            "infoplists" => select(\.infoPlist).starlark
            "deps" => {
                ":\(name)_library"
            }
            "frameworks" => {
                depsXcode
            }
            StarlarkProperty.Visibility.public
        }

        return builder.build()
    }
}
