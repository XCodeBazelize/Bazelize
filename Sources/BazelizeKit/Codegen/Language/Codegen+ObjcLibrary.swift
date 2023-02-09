//
//  Codegen+ObjcLibrary.swift
//
//
//  Created by Yume on 2022/8/8.
//

import Foundation
import RuleBuilder
import XCode

// TODO: https://github.com/XCodeBazelize/Bazelize/issues/7

extension Target {
    /// https://bazel.build/reference/be/objective-c
    ///
    /// objc_library(name, deps, srcs, data, hdrs, alwayslink, compatible_with, copts, defines, deprecation, distribs, enable_modules, exec_compatible_with, exec_properties, features, includes, licenses, linkopts, module_map, module_name, non_arc_srcs, pch, restricted_to, runtime_deps, sdk_dylibs, sdk_frameworks, sdk_includes, tags, target_compatible_with, testonly, textual_hdrs, toolchains, visibility, weak_sdk_frameworks)
    func generateObjcLibrary(_ builder: CodeBuilder, _: Kit) {
        builder.load(.objc_library)
        builder.add(.objc_library) {
            "name" => "\(name)_objc"
            "module_name" => name
            "srcs" => {
                srcs_c
                srcs_cpp
                srcs_objc
                srcs_objcpp
            }
            "hdrs" => {
                headers // TODO: pch
                hpps
            }
            "enable_modules" => select(\.enableModules).starlark
            "pch" => { }
            "copts" => {
                "-fblocks"
                "-fobjc-arc"
                "-fPIC"
                "-fmodule-name=\(name)"
            }
            "testonly" => isTest
            "defines" => { }
            "linkopts" => { }
            "includes" => {
                /// public header "."
                /// https://github.com/bazelbuild/bazel/issues/92
                "."
            }
            "deps" => {
                frameworksLibrary
            }
            StarlarkProperty.Visibility.private
        }

        builder.add("alias") {
            "name" => "\(name)_library"
            "actual" => "\(name)_objc"
            StarlarkProperty.Visibility.public
        }
    }
}
