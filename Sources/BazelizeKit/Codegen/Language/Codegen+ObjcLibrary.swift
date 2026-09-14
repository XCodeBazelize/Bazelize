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
    func generateObjcLibrary(_ builder: CodeBuilder, _ kit: Kit, aliasPublic: Bool = true) {
        let project = kit.project
        builder.load(.objc_library)
        builder.call(
            Rules.Objc.Call.objc_library(
                name: "\(name)_objc",
                srcs: .build {
                    srcs_c
                    srcs_cpp
                    srcs_objc
                    srcs_objcpp
                    internalHeaderFiles(project: project)
                    definesHeader
                },
                hdrs: .build {
                    flattenedModuleHeaderFiles(project: project)
                    prefixHeader
                },
                deps: .build {
                    frameworksLibrary
                    testHostLibraries(project: project)
                },
                copts: [
                    "-fblocks",
                    "-fobjc-arc",
                    "-fPIC",
                    "-fmodule-name=\(codegenModuleName)",
                ] + forceIncludeFlags,
                enable_modules: prefer(\.enableModules),
                includes: headerIncludes(project: project),
                linkopts: sdkLinkopts,
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
