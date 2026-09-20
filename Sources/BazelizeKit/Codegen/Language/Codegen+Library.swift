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
    /// The Swift module name, which is also what the generated Objective-C
    /// interop header is named after.
    ///
    /// `PRODUCT_MODULE_NAME` is the name a target's own sources import — UTM's
    /// `iOS` target builds a module called `UTM`, and its Objective-C sources
    /// include `UTM-Swift.h`. Without the setting Xcode falls back to the product
    /// name, and then to the target name.
    var codegenModuleName: String {
        let declared = prefer(\.metadata.moduleName)
            ?? prefer(\.metadata.productName)
            ?? name

        /// An unresolved reference is no name at all; a module name is an
        /// identifier, so anything else becomes an underscore.
        let resolved = declared.contains("$") || declared.isEmpty ? name : declared
        return String(resolved.map { character in
            character.isLetter || character.isNumber || character == "_" ? character : "_"
        })
    }

    func generateLibrary(_ builder: CodeBuilder, _ kit: Kit) {
        let name = name
        let cFamily = srcs_c + srcs_cpp + srcs_objc + srcs_objcpp

        generateAssets(builder, kit)
        generateResources(builder, kit)

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
                ] + clangDialectCopts + forceIncludeFlags,
                clang_srcs: .build {
                    srcs_c
                    srcs_cpp
                    srcs_objc
                    srcs_objcpp
                    internalHeaderFiles(project: project)
                    definesHeader
                },
                data: .build {
                    if !assets.isEmpty {
                        ":Assets"
                    }
                    copiedResourceGroups(project: project)
                },
                enable_modules: prefer(\.enableModules),
                hdrs: .build {
                    flattenedModuleHeaderFiles(project: project)
                    prefixHeader
                    /// A mixed target gets the bridging header's declarations through
                    /// its own clang module: `swiftc` rejects `-import-objc-header`
                    /// while building a module.
                    bridgingHeader
                },
                includes: headerIncludes(project: project),
                linkopts: sdkLinkopts,
                module_name: codegenModuleName,
                sdk_dylibs: dylibsSDK,
                sdk_frameworks: sdkFrameworks(project: project),
                swift_copts: moduleSwiftCopts(project: project),
                swift_defines: defines(project: project),
                swift_srcs: .build {
                    srcs_swift
                    intentSources
                    assetSymbolSources
                },
                tags: manual,
                weak_sdk_frameworks: weakFrameworksSDK,
                deps: .build {
                    linkedFrameworksLibrary(project: project)
                    testHostLibraries(project: project)
                    plugin
                    builtins
                },
                visibility: .private))

        builder.call(
            Rules.Builtin.Call.alias(
                name: "\(name)_library",
                actual: .named("\(name)_mixed"),
                tags: manual,
                visibility: .public))
    }

}
