//
//  SwiftPM+Generator+Product.swift
//
//
//  The rule a Swift target becomes, and the rule that stands for a product.
//

import BazelRules
import Foundation
@preconcurrency import PathKit
import Starlark
import Util

extension SwiftPM.Generator {
    func build(
        _ target: SwiftPM.PackageTarget,
        in package: SwiftPM.Package,
        prefix: String,
        generated: [String],
        resources: ResourceBundle?,
        builder: CodeBuilder)
    {
        /// The module under its own name, and once more under each name a
        /// consumer aliased it to: aliasing is that consumer's view of the
        /// module, and a module is named when it is compiled.
        for module in [target.name] + aliases(of: target.name, in: package) {
            let isAlias = module != target.name

            builder.load(loadableRule: Rules.Swift.swift_library)
            builder.call(
                Rules.Swift.Call.swift_library(
                    name: isAlias
                        ? Self.aliasRuleName(of: target.name, as: module)
                        : ruleName(of: target.name, in: package),
                    /// SwiftPM compiles every package target with the developer
                    /// search paths, which is how a test-support library finds
                    /// XCTest.
                    always_include_developer_search_paths: true,
                    copts: copts(of: target, in: package),
                    module_name: Self.moduleName(module),
                    /// Which targets `package` visibility reaches: every target of
                    /// the same package, which is what the name identifies.
                    package_name: package.manifest.name,
                    plugins: plugins(of: target, in: package),
                    srcs: sources(
                        naming: resources?.accessors ?? [],
                        globbing: matching(
                            sources(of: target, prefix: prefix, extensions: ["swift"]),
                            relativeFiles(of: target, in: package, prefix: prefix))
                            + generated,
                        excluding: excluded(target, prefix: prefix)),
                    deps: deps(of: target, in: package),
                    data: resources?.label.map { label in
                        .build { [Starlark.Label.named(label)] }
                    },
                    linkopts: linkopts(of: target, in: package),
                    tags: Self.manual,
                    visibility: .public))
        }
    }

    func build(
        _ product: SwiftPM.PackageProduct,
        emitted: Set<String>,
        package: SwiftPM.Package,
        builder: CodeBuilder)
    {
        switch product.kind {
        case .library:
            break
        case .executable:
            buildExecutable(product, emitted: emitted, package: package, builder: builder)
            return
        case .plugin:
            return
        }

        /// A macro is not part of a product a consumer links: it is loaded by
        /// the compiler of whatever declares the macro, inside its own package.
        let targets = product.targets.filter { target in
            emitted.contains(target) && !isMacro(target, in: package)
        }
        guard !targets.isEmpty else { return }

        /// A product of one target is that target under another name; several
        /// targets are a group that exports all of them.
        if targets.count == 1, let target = targets.first {
            guard target != product.name else { return }

            builder.call(
                Rules.Builtin.Call.alias(
                    name: product.name,
                    actual: .named(":\(ruleName(of: target, in: package))"),
                    tags: Self.manual,
                    visibility: .public))
            return
        }

        builder.load(loadableRule: Rules.Swift.swift_library_group)
        builder.call(
            Rules.Swift.Call.swift_library_group(
                name: product.name,
                deps: .build {
                    targets.sorted().map { target in
                        Starlark.Label.named(":\(ruleName(of: target, in: package))")
                    }
                },
                tags: Self.manual,
                visibility: .public))
    }
}
