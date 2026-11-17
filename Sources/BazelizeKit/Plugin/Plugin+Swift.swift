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

    /// rules_swift 4.2.x and 4.3.0 add the directory of every dependency's
    /// module map to `-I` when a generated Objective-C header is exported. For
    /// a framework that directory is `X.framework/Modules`: Clang finds the
    /// module there a second time, with another home, and rejects it
    /// (rules_swift#2004).
    ///
    /// This is the upstream fix, rules_swift#2015, applied to 4.2.2. No release
    /// has it yet; the patch goes when the pinned release does. The iOS
    /// fixture's `Mixed` target builds only with it.
    private static let frameworkModuleMapsPatch = """
    --- a/swift/internal/compiling.bzl
    +++ b/swift/internal/compiling.bzl
    @@ -1646,10 +1646,18 @@
             if module.clang and type(module.clang.module_map) == "File"
         ]).to_list()
         if module_maps:
    +        # Framework module maps are already discoverable through the dependency's
    +        # framework search paths. Adding their directory as a header search path
    +        # makes Clang also find them as non-framework modules, with a conflicting
    +        # module directory. Keep the maps as inputs, but omit those include paths.
             compilation_contexts = compilation_contexts + [
                 cc_common.create_compilation_context(
                     headers = depset(module_maps),
    -                includes = depset([module_map.dirname for module_map in module_maps]),
    +                includes = depset([
    +                    module_map.dirname
    +                    for module_map in module_maps
    +                    if ".framework/Modules" not in module_map.path
    +                ]),
                 ),
             ]
     
    """ + "\n"
}
