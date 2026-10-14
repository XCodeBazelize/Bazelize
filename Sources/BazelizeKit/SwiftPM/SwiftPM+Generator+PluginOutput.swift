//
//  SwiftPM+Generator+PluginOutput.swift
//
//
//  What a build tool plugin wrote, as inputs of the target's rules.
//

import BazelRules
import Foundation
@preconcurrency import PathKit
import Starlark
import Util

extension SwiftPM.Generator {
    /// What a plugin generated, linked next to the package's rules.
    ///
    /// Split the way SwiftPM splits it: a file whose extension the target
    /// compiles is a source of that target, anything else is one of its
    /// resources. A header is neither compiled nor bundled — it is an input of
    /// the generated source that includes it, which is the only thing SwiftPM
    /// lets reach it too.
    struct PluginGenerated {
        let sources: [String]
        let headers: [String]
        let resources: [String]

        static let none = PluginGenerated(sources: [], headers: [], resources: [])
    }

    /// What a plugin wrote for a target, split the way the target's own rule
    /// takes it, as patterns rather than names.
    ///
    /// The files are read where they belong: `bazel run //:plugins` wrote
    /// them into the package's `Generated/`, so nothing is moved or linked
    /// here and the output stands without the package's `.build`.
    ///
    /// What they are called is the plugin's business and changes when the
    /// plugin does, so the rules name the directory and the kinds of file in
    /// it, never a file. A later `bazel run //:plugins` writes a new set
    /// into the same place and the rules still hold.
    func materialize(
        pluginOutputsOf target: SwiftPM.PackageTarget,
        in package: SwiftPM.Package,
        at root: Path,
        kind: TargetKind) throws -> PluginGenerated
    {
        /// A target that asks for no plugin has no such directory, and a
        /// pattern for one would be a pattern for something that is never
        /// coming.
        guard !target.pluginUsages.isEmpty else { return .none }

        let directory = "Generated/\(target.name)Plugin"

        /// What the target's own rule compiles; a Swift target compiles Swift,
        /// and a C-family one whatever clang takes.
        let compiled: Set<String> = {
            if case .clang = kind { return Set(Self.compileExtensions) }
            return ["swift"]
        }()

        /// The kinds the target could compile, whether or not the plugin has
        /// run yet: the rules are written once and the files arrive later,
        /// from `bazel run //:plugins`.
        var sources = compiled
        var headers: Set<String> = {
            if case .clang = kind { return Set(Self.headerExtensions) }
            return []
        }()
        var resources: Set<String> = []
        var named: [String] = []

        let outputRoot = root + directory
        let base = outputRoot.normalize().string
        for file in Self.walk(outputRoot) {
            let path = file.normalize().string
            /// A file the plugin wrote somewhere else is not this target's
            /// to name.
            guard let relative = path.delete(prefix: base)?
                .trimmingCharacters(in: ["/"])
            else {
                continue
            }
            guard !relative.isEmpty else { continue }

            /// A file with no extension is the one thing a pattern cannot
            /// stand for, so that one is named.
            guard let `extension` = file.extension, !`extension`.isEmpty else {
                named.append("\(directory)/\(relative)")
                continue
            }

            if compiled.contains(`extension`) {
                sources.insert(`extension`)
            } else if Self.headerExtensions.contains(`extension`) {
                headers.insert(`extension`)
            } else {
                resources.insert(`extension`)
            }
        }

        func patterns(_ extensions: Set<String>) -> [String] {
            extensions.sorted().map { "\(directory)/**/*.\($0)" }
        }

        return .init(
            sources: patterns(sources),
            headers: patterns(headers),
            resources: patterns(resources) + named)
    }

    /// The macros a target loads: a macro target is a program the compiler
    /// runs, so it belongs in `plugins` rather than in `deps`. Its dependency
    /// condition still decides whether the compiler loads it.
    func plugins(of target: SwiftPM.PackageTarget, in package: SwiftPM.Package) -> Starlark.Value? {
        let macros = Set(package.manifest.targets.compactMap { other -> String? in
            if case .macro = kinds[package.directory]?[other.name] { return other.name }
            return nil
        })

        return conditionalDependencies(of: target, in: package) { dependency in
            switch dependency.kind {
            case .target(let name), .byName(let name):
                guard macros.contains(name) else { return [] }
                return [":\(ruleName(of: name, in: package))"]
            case .product:
                return []
            }
        }
    }
}
