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
    func generateSwiftLibrary(_ builder: inout Build.Builder, _ kit: Kit) {
        let plugins = kit.plugins.compactMap {
            $0[name]
        }

        builder.load(.swift_library)
        builder.add(.swift_library) {
            "name" => "\(name)_swift"
            "module_name" => name
            "srcs" => {
                srcs_swift
            }
            "testonly" => isTest
            "deps" => {
                .comment("Framework TODO (swift_library/objc_library)")
                frameworks_library

                plugins.flatMap(\.deps)
            }
//            "data" => {
//                resources
//            }
            StarlarkProperty.Visibility.private
        }

        builder.add("alias") {
            "name" => "\(name)_library"
            "actual" => "\(name)_swift"
            StarlarkProperty.Visibility.public
        }
    }
}
