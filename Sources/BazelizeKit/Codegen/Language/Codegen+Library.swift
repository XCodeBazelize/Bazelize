//
//  Codegen+Library.swift
//
//
//  Created by Yume on 2022/8/23.
//

import Foundation
import Util
import Starlark

extension Target {
    var codegenModuleName: String {
        name.replacingOccurrences(of: "-", with: "_")
    }

    func generateLibrary(_ builder: CodeBuilder, _ kit: Kit) {
        let name = name
        let cFamily = srcs_c + srcs_cpp + srcs_objc + srcs_objcpp

        generateAssets(builder, kit)

        switch (cFamily.isEmpty, srcs_swift.isEmpty) {
        case (true, false):
            generateSwiftLibrary(builder, kit)
        case (false, true):
            generateObjcLibrary(builder, kit)
        case (false, false):
            generateMixedLanguageLibrary(builder, kit)
        case (true, true):
            Log.codeGenerate.warning("Target(\(name, privacy: .public)) can't happen")
        }
    }

    private func generateMixedLanguageLibrary(_ builder: CodeBuilder, _ kit: Kit) {
        let project = kit.project
        let plugin = kit.plugins.compactMap {
            $0[name]
        }.flatMap(\.deps)

        let builtins: [String] = kit.builtinPlugins
            .compactMap(\.target)
            .reduce([]) { origin, next in
                let data = next[name] ?? []
                return origin + data
            }

        builder.load(.mixed_language_library)
        builder.call(
            Rules.Swift.Call.mixed_language_library(
                name: "\(name)_mixed",
                clang_copts: [
                    "-fblocks",
                    "-fobjc-arc",
                    "-fPIC",
                    "-fmodule-name=\(codegenModuleName)",
                ] + clangDialectCopts,
                clang_srcs: .build {
                    srcs_c
                    srcs_cpp
                    srcs_objc
                    srcs_objcpp
                    internalHeaderFiles(project: project)
                },
                data: .build {
                    if !assets.isEmpty {
                        ":Assets"
                    }
                    xibs
                    storyboards
                },
                hdrs: .build {
                    moduleHeaderFiles(project: project)
                    /// A mixed target gets the bridging header's declarations through
                    /// its own clang module: `swiftc` rejects `-import-objc-header`
                    /// while building a module.
                    bridgingHeader
                },
                includes: headerIncludes(project: project),
                module_name: codegenModuleName,
                sdk_dylibs: dylibsSDK,
                sdk_frameworks: frameworksSDK,
                swift_copts: moduleSwiftCopts,
                swift_defines: defines(project: project),
                swift_srcs: .build {
                    srcs_swift
                    intentSources
                },
                weak_sdk_frameworks: weakFrameworksSDK,
                deps: .build {
                    linkedFrameworksLibrary(project: project)
                    applicationHost(project: project)
                    plugin
                    builtins
                },
                visibility: .private))

        builder.call(
            Rules.Builtin.Call.alias(
                name: "\(name)_library",
                actual: .named("\(name)_mixed"),
                visibility: .public))
    }

}
