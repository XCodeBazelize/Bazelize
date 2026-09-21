//
//  SwiftPM+Macro.swift
//
//
//  Rules for a package target the compiler loads instead of linking.
//

import BazelRules
import Foundation
@preconcurrency import PathKit
import Starlark
import Util

extension SwiftPM.Generator {
    /// A macro target becomes a `swift_compiler_plugin`: a program the compiler
    /// runs while it compiles whatever declares the macro.
    ///
    /// It is built for the machine doing the building rather than the platform the
    /// project targets, which is why it cannot be an ordinary library — and why a
    /// target that uses the macro lists it in `plugins`, never in `deps`.
    func buildMacro(
        _ target: SwiftPM.PackageTarget,
        in package: SwiftPM.Package,
        prefix: String,
        generated: [String],
        builder: CodeBuilder)
    {
        builder.load(loadableRule: Rules.Swift.swift_compiler_plugin)
        builder.call(
            Rules.Swift.Call.swift_compiler_plugin(
                name: ruleName(of: target.name, in: package),
                srcs: Starlark.glob(
                    matching(
                        sources(of: target, prefix: prefix, extensions: ["swift"]),
                        relativeFiles(of: target, in: package, prefix: prefix))
                        + generated,
                    exclude: excluded(target, prefix: prefix),
                    allowEmpty: true),
                copts: copts(of: target, in: package),
                deps: deps(of: target, in: package),
                module_name: Self.moduleName(target.name),
                tags: Self.manual,
                visibility: .public))
    }
}
