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
        let project = kit.project
        builder.load(.objc_library)
        let copts = ["-fblocks", "-fPIC", "-fmodule-name=\(codegenModuleName)"]
            + clangDialectCopts + forceIncludeFlags + clangCopts(kit)
        var groups: [String] = []
        for (index, group) in fileFlags.groups.enumerated() {
            let groupName = "\(name)_objc_flags_\(index)"
            groups.append(":\(groupName)")
            builder.call(Rules.Objc.Call.objc_library(
                name: groupName,
                srcs: .build {
                    group.sources
                    internalHeaderFiles(project: project)
                    flattenedModuleHeaderFiles(project: project)
                    prefixHeader
                    definesHeader
                },
                deps: .build {
                    linkedFrameworksLibrary(project: project)
                    testHostLibraries(project: project)
                },
                copts: (copts + group.copts).starlark,
                enable_modules: prefer(\.enableModules),
                includes: headerIncludes(project: project),
                non_arc_srcs: group.nonArcSources.nonEmpty.map { paths in .build { paths } },
                sdk_dylibs: dylibsSDK,
                sdk_frameworks: sdkFrameworks(project: project, available: kit.availableFrameworks(for: self)),
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
                    internalHeaderFiles(project: project)
                    definesHeader
                },
                hdrs: .build {
                    flattenedModuleHeaderFiles(project: project)
                    prefixHeader
                },
                deps: .build {
                    linkedFrameworksLibrary(project: project)
                    testHostLibraries(project: project)
                    groups
                },
                data: .build {
                    if !assets.isEmpty {
                        ":Assets"
                    }
                    copiedResourceGroups(project: project)
                },
                copts: copts.starlark,
                enable_modules: prefer(\.enableModules),
                includes: headerIncludes(project: project),
                linkopts: sdkLinkopts?.starlark,
                module_name: codegenModuleName,
                non_arc_srcs: fileFlags.nonArcSources.nonEmpty.map { paths in .build { paths } },
                sdk_dylibs: dylibsSDK,
                sdk_frameworks: sdkFrameworks(project: project, available: kit.availableFrameworks(for: self)),
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
