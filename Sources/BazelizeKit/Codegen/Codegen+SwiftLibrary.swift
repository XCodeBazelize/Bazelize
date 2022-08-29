//
//  Codegen+SwiftLibrary.swift
//
//
//  Created by Yume on 2022/7/4.
//

import Foundation
import RuleBuilder
import XCode

extension Target {
    /// https://github.com/bazelbuild/rules_swift/blob/master/doc/rules.md#swift_library
    /// swift_library(name, alwayslink, copts, data, defines, deps, generated_header_name, generates_header, linkopts, linkstatic, module_name, private_deps, srcs, swiftc_inputs)
    #warning("todo check pure swift, or mix objc & swift")
    func generateSwiftLibrary(_ kit: Kit) -> String {
        #warning("plugin")

        let plugins = kit.plugins.compactMap {
            $0[name]
        }

        var builder = Build.Builder()
        builder.load(.swift_library)
        builder.add(.swift_library) {
            "name" => "\(name)_swift"
            "module_name" => name
            "srcs" => {
                .comment("srcs")
                srcs
            }
            "deps" => {
                .comment("Framework TODO (swift_library/objc_library)")
                frameworks_library

                plugins.flatMap(\.deps)
            }
            StarlarkProperty.Visibility.private
        }

        builder.add("alias") {
            "name" => "\(name)_library"
            "actual" => "\(name)_swift"
            StarlarkProperty.Visibility.public
        }

        return builder.build()
    }
}
