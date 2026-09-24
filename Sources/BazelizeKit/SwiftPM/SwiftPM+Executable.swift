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
                copts: copts(of: target, in: package),
                deps: deps(of: target, in: package),
                linkopts: linkopts(of: target, in: package),
                module_name: Self.moduleName(target.name),
                srcs: Starlark.glob(
                    matching(
                        sources(of: target, prefix: prefix, extensions: ["swift"]),
                        relativeFiles(of: target, in: package, prefix: prefix))
                        + generated
                        + (resources?.accessors ?? []),
                    exclude: excluded(target, prefix: prefix),
                    allowEmpty: true),
                tags: Self.manual,
                visibility: .public))
    }

    /// A file under `Snippets/` is an implicit executable target: SwiftPM
    /// builds one program per file, with every library target of the package
    /// available to it. The manifest never mentions them, so they are found on
    /// disk.
    ///
    /// The link is called `main.swift` because that is what the file is: a
    /// snippet is top-level code, which only the entry point may hold.
    func buildSnippets(
        in package: SwiftPM.Package,
        root: Path,
        emitted: [String: TargetKind],
        builder: CodeBuilder) throws
    {
        let directory = package.root + "Snippets"
        guard directory.isDirectory else { return }

        let dependencies = emitted.compactMap { name, kind -> String? in
            switch kind {
            case .swift, .clang, .binary, .system:
                return ":\(ruleName(of: name, in: package))"
            case .macro, .executable, .test, .unsupported:
                return nil
            }
        }.sorted()

        for source in ((try? directory.children()) ?? [])
            .filter({ $0.extension == "swift" })
            .sorted(by: { $0.lastComponent < $1.lastComponent })
        {
            let name = source.lastComponentWithoutExtension
            let prefix = "\(Self.sourcesRoot)/\(name)"
            let destination = root + prefix
            try destination.mkpath()
            let link = destination + "main.swift"
            if link.isSymlink || link.exists { try? link.delete() }
            try link.symlink(source)

            builder.load(loadableRule: Rules.Swift.swift_binary)
            builder.call(
                Rules.Swift.Call.swift_binary(
                    name: name,
                    copts: ["-DSWIFT_PACKAGE", "-Xcc", "-DSWIFT_PACKAGE"],
                    deps: .build { dependencies.map { Starlark.Label.named($0) } },
                    module_name: Self.moduleName(name),
                    srcs: Starlark.glob(["\(prefix)/main.swift"]),
                    tags: Self.manual,
                    visibility: .public))
        }
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
