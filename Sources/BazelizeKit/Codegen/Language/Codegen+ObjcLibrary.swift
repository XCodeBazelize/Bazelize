//
//  Codegen+ObjcLibrary.swift
//
//
//  Created by Yume on 2022/8/8.
//

import BazelRules
import Foundation
import Starlark

// TODO: https://github.com/XCodeBazelize/Bazelize/issues/7

extension Target {
    func generateObjcLibrary(_ builder: CodeBuilder, _: Kit, aliasPublic: Bool = true) {
        builder.load(.objc_library)
        /// "enable_modules" => select(\.enableModules).starlark
        builder.call(
            Rules.Objc.Call.objc_library(
                name: "\(name)_objc",
                srcs: .build {
                    srcs_c
                    srcs_cpp
                    srcs_objc
                    srcs_objcpp
                },
                hdrs: .build {
                    // FIXME: (@yume190) TODO: pch
                    headers
                    hpps
                },
                deps: .build {
                    frameworksLibrary
                },
                copts: [
                    "-fblocks",
                    "-fobjc-arc",
                    "-fPIC",
                    "-fmodule-name=\(codegenModuleName)",
                ],
                includes: [
                    /// public header "."
                    /// https://github.com/bazelbuild/bazel/issues/92
                    ".",
                ],
                module_name: codegenModuleName,
                sdk_dylibs: dylibsSDK,
                sdk_frameworks: frameworksSDK,
                testonly: isTest,
                visibility: .private,
                weak_sdk_frameworks: weakFrameworksSDK))

        if aliasPublic {
            builder.call(
                Rules.Builtin.Call.alias(
                    name: "\(name)_library",
                    actual: .named("\(name)_objc"),
                    visibility: .public))
        }
    }
}
