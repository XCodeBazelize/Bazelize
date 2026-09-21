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
    /// A test target of the package handed in becomes a test bundle over a library
    /// of its sources.
    ///
    /// The tests of a package a project merely depends on are not generated:
    /// running them says nothing about the project, and they pull in dependencies
    /// nothing else needs. The tests of the package under the tool are the whole
    /// point of pointing the tool at it.
    ///
    /// It is a bundle rather than a plain `swift_test` because a test target has
    /// resources like any other, and only a bundling rule puts them where
    /// `Bundle.module` looks.
    func buildTest(
        _ target: SwiftPM.PackageTarget,
        in package: SwiftPM.Package,
        prefix: String,
        generated: [String],
        resources: ResourceBundle?,
        builder: CodeBuilder)
    {
        let name = ruleName(of: target.name, in: package)
        let library = "\(name)_library"

        builder.load(loadableRule: Rules.Swift.swift_library)
        builder.call(
            Rules.Swift.Call.swift_library(
                name: library,
                always_include_developer_search_paths: true,
                copts: copts(of: target, in: package),
                module_name: Self.moduleName(target.name),
                package_name: package.manifest.name,
                srcs: Starlark.glob(
                    matching(
                        sources(of: target, prefix: prefix, extensions: ["swift"]),
                        relativeFiles(of: target, in: package, prefix: prefix))
                        + generated
                        + (resources?.accessors ?? []),
                    exclude: excluded(target, prefix: prefix),
                    allowEmpty: true),
                deps: deps(of: target, in: package),
                data: resources?.label.map { label in
                    .build { [Starlark.Label.named(label)] }
                },
                linkopts: linkopts(of: target, in: package),
                tags: Self.manual,
                testonly: true,
                visibility: .private))

        builder.load(.macos_unit_test)
        builder.call(
            Rules.Apple.MacOS.Call.macos_unit_test(
                name: name,
                deps: .build { [Starlark.Label.named(":\(library)")] },
                /// A package's tests run where the tool runs, so the version is the
                /// one the package asks of macOS.
                minimum_os_version: deployment.required(package, platform: "macos"),
                visibility: .public))
    }
}
