//
//  SwiftPM+Test.swift
//
//
//  Rules for the tests of the package that was handed to bazelize.
//

import BazelRules
import Foundation
@preconcurrency import PathKit
import Starlark
import Util

extension SwiftPM.Generator {
    /// A test target becomes a `swift_test`, for the package that was handed in.
    ///
    /// The tests of a package a project merely depends on are not the project's
    /// tests: running them says nothing about the project, and they pull in test
    /// dependencies nothing else needs. The tests of the package under the tool are
    /// the whole point of pointing the tool at it.
    func buildTest(
        _ target: SwiftPM.PackageTarget,
        in package: SwiftPM.Package,
        prefix: String,
        generated: [String],
        resources: ResourceBundle?,
        builder: CodeBuilder)
    {
        builder.load(loadableRule: Rules.Swift.swift_test)
        builder.call(
            Rules.Swift.Call.swift_test(
                name: ruleName(of: target.name, in: package),
                copts: copts(of: target).nonEmpty,
                data: resources.map { bundle in
                    .build { [Starlark.Label.named(bundle.label)] }
                },
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
                visibility: .public))
    }
}
