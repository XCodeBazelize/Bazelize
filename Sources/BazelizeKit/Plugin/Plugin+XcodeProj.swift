//
//  PluginXcodeProj.swift
//
//
//  Created by Yume on 2023/2/3.
//

import Foundation
import Starlark

// MARK: - PluginXcodeProj

/// https://github.com/MobileNativeFoundation/rules_xcodeproj
final class PluginXcodeProj: PluginBuiltin {
    let dep: BazelDep.XcodeProj = .latest
    override func module(_ builder: CodeBuilder) {
        builder.bazel_dep(
            name: "rules_xcodeproj",
            version: dep.rawValue)
    }

    /// Every target that generated a rule, under the project's own name.
    ///
    /// A label that names nothing fails analysis of the whole rule, so a target
    /// without sources — which generates no rule — is left out. Each one is a
    /// top level target at its default environment: building for a device needs a
    /// provisioning profile, which no Xcode project hands over.
    override func build(_ builder: CodeBuilder) {
        let labels = kit.project.targets
            .filter(\.hasSources)
            .map(\.name)
            .sorted()
            .map { name in
                Starlark.Label.named("//Targets/\(name):\(name)")
            }

        guard !labels.isEmpty else { return }

        builder.load(
            module: "@rules_xcodeproj//xcodeproj:defs.bzl",
            symbols: ["xcodeproj"])

        builder.call(
            Starlark.Statement.Call("xcodeproj") {
                "name" => "xcodeproj"
                "project_name" => kit.project.name
                "tags" => ["manual"]
                "top_level_targets" => labels
            })
    }
}
