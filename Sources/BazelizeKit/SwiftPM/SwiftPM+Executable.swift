//
//  SwiftPM+Executable.swift
//
//
//  Rules for a command line tool a package builds.
//

import BazelRules
import Foundation
@preconcurrency import PathKit
import Starlark
import Util

extension SwiftPM.Generator {
    /// An executable target becomes a `swift_binary`: it has a `main`, so it links
    /// instead of being linked, and a library rule would neither produce a tool nor
    /// compile a top-level `main.swift`.
    func buildExecutable(
        _ target: SwiftPM.PackageTarget,
        in package: SwiftPM.Package,
        prefix: String,
        generated: [String],
        resources: ResourceBundle?,
        builder: CodeBuilder)
    {
        builder.load(loadableRule: Rules.Swift.swift_binary)
        builder.call(
            Rules.Swift.Call.swift_binary(
                name: ruleName(of: target.name, in: package),
                copts: copts(of: target).nonEmpty,
                deps: deps(of: target, in: package).nonEmpty.map { labels in
                    .build { labels }
                },
                linkopts: linkopts(of: target).nonEmpty,
                module_name: Self.moduleName(target.name),
                srcs: Starlark.glob(
                    matching(
                        sources(of: target, prefix: prefix, extensions: ["swift"]),
                        relativeFiles(of: target, in: package, prefix: prefix))
                        + generated
                        + (resources?.accessors ?? []),
                    exclude: excluded(target, prefix: prefix)),
                tags: Self.manual,
                visibility: .public))
    }

    /// An executable product is the tool under the name a consumer writes, so it
    /// aliases the target rather than wrapping it: two `swift_binary` rules over
    /// the same sources would build the tool twice.
    func buildExecutable(
        _ product: SwiftPM.PackageProduct,
        emitted: Set<String>,
        package: SwiftPM.Package,
        builder: CodeBuilder)
    {
        guard let target = product.targets.first(where: emitted.contains) else { return }
        let rule = ruleName(of: target, in: package)
        guard rule != product.name else { return }

        builder.call(
            Rules.Builtin.Call.alias(
                name: product.name,
                actual: .named(":\(rule)"),
                tags: Self.manual,
                visibility: .public))
    }
}
