//
//  SwiftPM+Generator+Target.swift
//
//
//  Which targets of a package become rules, and what each one is called.
//

import BazelRules
import Foundation
@preconcurrency import PathKit
import Starlark
import Util

extension SwiftPM.Generator {
    /// The targets that can be generated, after dropping everything that depends
    /// on one that cannot: a library missing a target it links is worse than a
    /// library that is not there at all.
    func supportedTargets(of package: SwiftPM.Package) throws -> [String: TargetKind] {
        /// Which targets are generated is `kind(of:)`'s answer, tests included:
        /// the package under the tool gets its tests, one a project depends on
        /// does not.
        let targets = package.manifest.targets
        var supported: [String: TargetKind] = [:]

        for target in targets {
            guard let kind = try kind(of: target, in: package) else { continue }
            switch kind {
            case .swift, .clang, .binary, .system, .macro, .executable, .test:
                supported[target.name] = kind
            case .unsupported(let reason):
                /// A target nothing is generated for is a target whatever
                /// links it will not find, and the error that follows names
                /// the module rather than the reason it is missing.
                note("\(package.directory)/\(target.name) is not generated: \(reason).")
            }
        }

        let names = Set(targets.map(\.name))
        var changed = true
        while changed {
            changed = false
            for target in targets where supported[target.name] != nil {
                let missing = target.dependencies.compactMap { dependency -> String? in
                    switch dependency.kind {
                    case .target(let name), .byName(let name):
                        guard names.contains(name), supported[name] == nil else { return nil }
                        return name
                    case .product:
                        return nil
                    }
                }
                guard let first = missing.first else { continue }

                supported[target.name] = nil
                changed = true
                note("""
                \(package.directory)/\(target.name) is not generated: it depends on \(first), \
                which is not generated either.
                """)
            }
        }

        return supported
    }

    enum TargetKind {
        case swift
        case clang
        case binary
        case system
        /// A macro: a program the compiler loads, not a library the target links.
        case macro
        /// A command line tool the package builds.
        case executable
        /// A test suite, generated for the package the tool was pointed at.
        case test
        case unsupported(String)
    }

    /// What the target is made of, decided by the files on disk: the manifest
    /// only says `regular`.
    private func kind(of target: SwiftPM.PackageTarget, in package: SwiftPM.Package) throws -> TargetKind? {
        switch target.type {
        case "test":
            /// Only the package under the tool: the tests of a package a project
            /// depends on say nothing about the project.
            return package.isRoot ? .test : nil
        case "plugin":
            /// A plugin is a program SwiftPM runs, never a rule this workspace
            /// builds: a command plugin runs when someone asks for it by name,
            /// and a build tool plugin runs while the workspace is generated.
            /// Whether it ran is what the run reports.
            return nil
        case "binary":
            return .binary
        case "system":
            return .system
        case "macro":
            return .macro
        case "executable", "snippet":
            /// A tool the package builds: it has a `main`, so it links rather
            /// than being linked.
            return .executable
        default:
            break
        }

        guard sourceDirectory(of: target, in: package) != nil else {
            return .unsupported("no source directory")
        }

        let extensions = extensions(of: target, in: package)
        guard !extensions.isEmpty else {
            return .unsupported("no sources")
        }

        /// A target with any Swift in it is a Swift target: SwiftPM does not
        /// allow one target to mix languages, so the C-family files that are
        /// still on disk belong to another target or are excluded.
        return extensions.contains("swift") ? .swift : .clang
    }

    /// The rule that stands for a target.
    ///
    /// A product may carry the name of a target while grouping several of them.
    /// SwiftPM allows that; two rules cannot share one name, so the product
    /// keeps the name a consumer writes and the target's own rule is suffixed.
    func ruleName(of target: String, in package: SwiftPM.Package) -> String {
        let grouped = package.manifest.products
            .filter { $0.kind == .library && $0.targets.count > 1 }
            .map(\.name)

        return grouped.contains(target) ? "\(target)_target" : target
    }

    /// What consumers call this package's module instead of its own name.
    func aliases(of target: String, in package: SwiftPM.Package) -> [String] {
        (moduleAliases[package.directory]?[target] ?? []).sorted()
    }

    /// The rule that compiles a target under an alias: a name of its own,
    /// because the alias is often what a product is already called.
    static func aliasRuleName(of target: String, as alias: String) -> String {
        "\(target)_as_\(alias)"
    }

    func isMacro(_ target: String, in package: SwiftPM.Package) -> Bool {
        if case .macro = kinds[package.directory]?[target] { return true }
        return false
    }

    /// Swift module names are identifiers; a package name is not.
    static func moduleName(_ name: String) -> String {
        String(name.map { character in
            character.isLetter || character.isNumber || character == "_" ? character : "_"
        })
    }
}
