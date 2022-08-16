//
//  Codegen+Framework.swift
//
//
//  Created by Yume on 2022/4/29.
//

import Foundation
import RuleBuilder
import XCode

extension Target {
    func generateFrameworkCode(_ kit: Kit) -> String {
        precondition(setting.bundleID != nil, "bundle id")
        precondition(setting.iOS != nil, "min version")

        let depsXcode = ""

        var builder = Build.Builder()
        builder.load(.ios_framework)
        builder.custom(generateSwiftLibrary(kit))

        builder.add(.ios_framework) {
            "name" => name
            "bundle_id" => setting.bundleID
            "families" => setting.deviceFamily
            "minimum_os_version" => setting.iOS
            "infoplists" => setting.infoPlist
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
