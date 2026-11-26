//
//  Codegen+ObjcLibrary.swift
//
//
//  Created by Yume on 2022/8/8.
//

import BazelRules
import Foundation
import Starlark

extension Target {
    func generateObjcLibrary(_ builder: CodeBuilder, _ kit: Kit, fileFlags: FileCompilerPlan, aliasPublic: Bool = true) {
        builder.load(.objc_library)
        let copts = Self.tokenized(
            ["-fblocks", "-fPIC", "-fmodule-name=\(codegenModuleName)"]
                + clangDialectCopts + forceIncludeFlags + clangCopts(kit))
        var groups: [String] = []
        for (index, group) in fileFlags.groups.enumerated() {
            let groupName = "\(name)_objc_flags_\(index)"
            groups.append(":\(groupName)")
            builder.call(Rules.Objc.Call.objc_library(
                name: groupName,
                srcs: .build {
                    group.sources
                    internalHeaderFiles(project: kit.project)
                    flattenedModuleHeaderFiles(project: kit.project)
                    prefixHeader
                    definesHeader
                },
                deps: .build {
                    linkedFrameworksLibrary(project: kit.project)
                    testHostLibraries(project: kit.project)
                },
                copts: (copts + group.copts).starlark,
                enable_modules: prefer(\.enableModules),
                includes: headerIncludes(project: kit.project),
                non_arc_srcs: group.nonArcSources.nonEmpty.map { paths in .build { paths } },
                sdk_dylibs: dylibsSDK,
                sdk_frameworks: sdkFrameworks(project: kit.project, available: kit.availableFrameworks(for: self)),
                tags: manual,
                testonly: isTest,
                visibility: .private,
                weak_sdk_frameworks: weakFrameworksSDK))
        }
        builder.call(
            Rules.Objc.Call.objc_library(
                name: "\(name)_objc",
                srcs: .build {
                    fileFlags.sources
                    internalHeaderFiles(project: kit.project)
                    definesHeader
                },
                hdrs: .build {
                    flattenedModuleHeaderFiles(project: kit.project)
                    prefixHeader
                },
                deps: .build {
                    linkedFrameworksLibrary(project: kit.project)
                    testHostLibraries(project: kit.project)
                    groups
                },
                data: .build {
                    if !assets.isEmpty {
                        ":Assets"
                    }
                    copiedResourceGroups(project: kit.project)
                },
                copts: copts.starlark,
                enable_modules: prefer(\.enableModules),
                includes: headerIncludes(project: kit.project),
                linkopts: sdkLinkopts.map(Self.tokenized)?.starlark,
                module_name: codegenModuleName,
                non_arc_srcs: fileFlags.nonArcSources.nonEmpty.map { paths in .build { paths } },
                sdk_dylibs: dylibsSDK,
                sdk_frameworks: sdkFrameworks(project: kit.project, available: kit.availableFrameworks(for: self)),
                tags: manual,
                testonly: isTest,
                visibility: .private,
                weak_sdk_frameworks: weakFrameworksSDK))

        if aliasPublic {
            builder.call(
                Rules.Builtin.Call.alias(
                    name: "\(name)_library",
                    actual: .named("\(name)_objc"),
                    tags: manual,
                    visibility: .public))
        }
    }
}
