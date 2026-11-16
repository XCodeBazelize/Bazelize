//
//  PluginSwift.swift
//
//
//  Created by Yume on 2023/2/3.
//

import Foundation
import Starlark

// MARK: - PluginSwift

/// https://github.com/bazelbuild/rules_swift
final class PluginSwift: PluginBuiltin {
    let dep: BazelDep.Swift = .latest

    override func module(_ builder: CodeBuilder) {
        builder.bazel_dep(
            name: "rules_swift",
            version: dep.rawValue,
            repo_name: "build_bazel_rules_swift")
        if dep == .v4_2_2 {
            builder.call(.init("single_version_override") {
                "module_name" => "rules_swift"
                "version" => dep.rawValue
                "patches" => ["//tools/rules_swift:framework_module_maps.patch"]
                "patch_strip" => 1
            })
        }
        builder.custom("""
        system_sdk = use_extension("@build_bazel_rules_swift//swift:extensions.bzl", "system_sdk")
        system_sdk.configure_sdks(
            names = [
                "AppleTVOS",
                "AppleTVSimulator",
                "MacOSX",
                "WatchOS",
                "WatchSimulator",
                "XROS",
                "XRSimulator",
                "iPhoneOS",
                "iPhoneSimulator",
            ],
        )
        """)
    }

    override var custom: [PluginBuiltin.Custom]? {
        guard dep == .v4_2_2 else { return nil }
        return [
            .init(
                path: "tools/rules_swift/BUILD",
                content: "exports_files([\"framework_module_maps.patch\"])\n"),
            .init(
                path: "tools/rules_swift/framework_module_maps.patch",
                content: Self.frameworkModuleMapsPatch),
        ]
    }

    /// rules_swift 4.2.2 adds framework Modules directories to -I when exporting
    /// generated Objective-C headers. Keep their module home at the framework
    /// root; ordinary Clang module maps still need their include directories.
    private static let frameworkModuleMapsPatch = """
    --- a/swift/internal/compiling.bzl
    +++ b/swift/internal/compiling.bzl
    @@ -1639,17 +1639,23 @@
         # Generated headers can import Clang modules whose maps are carried only by
         # SwiftInfo. Add maps from public direct dependencies as transitive
         # compilation inputs.
    -    module_maps = depset([
    -        module.clang.module_map
    +    clang_modules = [
    +        module
             for swift_info in swift_infos
             for module in swift_info.direct_modules
             if module.clang and type(module.clang.module_map) == "File"
    -    ]).to_list()
    -    if module_maps:
    +    ]
    +    if clang_modules:
             compilation_contexts = compilation_contexts + [
                 cc_common.create_compilation_context(
    -                headers = depset(module_maps),
    -                includes = depset([module_map.dirname for module_map in module_maps]),
    +                headers = depset([module.clang.module_map for module in clang_modules]),
    +                # Frameworks are discovered through -F. Adding their Modules
    +                # directory to -I changes Clang's module home and invalidates PCMs.
    +                includes = depset([
    +                    module.clang.module_map.dirname
    +                    for module in clang_modules
    +                    if not module.is_framework
    +                ]),
                 ),
             ]
     
    """ + "\n"
}
