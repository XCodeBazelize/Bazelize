//
//  Codegen+Framework.swift
//
//
//  Created by Yume on 2022/4/29.
//

import BazelRules
import Foundation
import Starlark
import XCode

// TODO: https://github.com/XCodeBazelize/Bazelize/issues/8 framework(static/dynamic)

extension Target {
    func generateFrameworkCode(_ builder: CodeBuilder, _: Kit) {
        builder.load(.ios_framework)
        builder.call(
            Rules.Apple.IOS.Call.ios_framework(
                name: name,
                bundle_id: prefer(\.bundleID),
                deps: .build {
                    ":\(name)_library"
                    frameworks
                },
                families: prefer(\.deviceFamily)?.map(\.code),
                infoplists: .build {
                    plist_file
                    plist_auto
                    // plist_default
                },
                minimum_os_version: prefer(\.iOS),
                visibility: .public))
    }
}
