//
//  SwiftPM+Settings.swift
//
//
//  `SwiftSetting` and `LinkerSetting` as compiler and linker flags.
//

import Foundation
import Starlark

extension SwiftPM.Generator {
    /// What the target compiles with, beyond the defaults.
    ///
    /// SwiftPM hands these to `swiftc` directly, so they are copts rather than
    /// anything the rules model: a `defines` attribute would re-tokenize a value
    /// and a feature is not a flag the rules know.
    ///
    /// A setting conditional on a trait is a `select` on that trait's flag, so
    /// the build decides it rather than this run.
    func copts(of target: SwiftPM.PackageTarget, in package: SwiftPM.Package) -> Starlark.Value? {
        grouped(
            target.settings,
            in: package,
            /// `SWIFT_PACKAGE` is what a package's own sources test for; SwiftPM
            /// defines it for every target it builds.
            ///
            /// A flag, not the `defines` attribute: that attribute propagates to
            /// everything that depends on the library, and a project's own target
            /// must not compile as if it were a package — Xcode's generated asset
            /// symbols, for one, switch on `SWIFT_PACKAGE`.
            always: Self.define("SWIFT_PACKAGE"),
            /// A trait is a compilation condition of the package that declares
            /// it: `#if Fast` is how a source asks. Swift only — SwiftPM does
            /// not hand it to clang, so neither is it handed to `-Xcc`.
            conditional: traitDefines(of: package),
            flags: Self.swiftFlags)
    }

    /// `-D<Trait>` for every trait the package declares, each behind its own
    /// flag: the traits the build turned on are the ones defined.
    private func traitDefines(of package: SwiftPM.Package) -> [(condition: String, values: [String])] {
        package.manifest.traits
            .filter { $0.name != "default" }
            .sorted { $0.name < $1.name }
            .compactMap { trait in
                guard let condition = traitCondition([trait.name], in: package) else { return nil }
                return (condition, ["-D\(trait.name)"])
            }
    }

    /// A package can name a system library or framework it needs; nothing else in
    /// the graph knows about it.
    func linkopts(of target: SwiftPM.PackageTarget, in package: SwiftPM.Package) -> Starlark.Value? {
        grouped(target.settings, in: package, always: [], flags: Self.linkerFlags)
    }

    /// The flags of one Swift setting.
    private static func swiftFlags(_ setting: SwiftPM.Setting) -> [String] {
        guard setting.tool == "swift", let name = setting.name else { return [] }

        switch name {
        case "define":
            return setting.values.flatMap { define(String($0)) }
        case "swiftLanguageMode", "swiftLanguageVersion":
            guard let version = setting.values.first else { return [] }
            return ["-swift-version", version]
        case "defaultIsolation":
            guard let isolation = setting.values.first else { return [] }
            return ["-default-isolation", isolation]
        case "enableUpcomingFeature":
            return setting.values.flatMap { feature in
                ["-enable-upcoming-feature", feature]
            }
        case "enableExperimentalFeature":
            return setting.values.flatMap { feature in
                ["-enable-experimental-feature", feature]
            }
        case "strictMemorySafety":
            return ["-strict-memory-safety"]
        case "interoperabilityMode":
            /// The manifest names the language; the compiler takes a mode.
            /// `.C` is what it does anyway, and has no flag.
            guard setting.values.first == "Cxx" else { return [] }
            return ["-cxx-interoperability-mode=default"]
        case "unsafeFlags":
            return setting.values
        default:
            return []
        }
    }

    private static func linkerFlags(_ setting: SwiftPM.Setting) -> [String] {
        guard setting.tool == "linker", let name = setting.name else { return [] }

        switch name {
        case "linkedLibrary":
            return setting.values.map { library in
                "-l\(library)"
            }
        case "linkedFramework":
            return setting.values.flatMap { framework in
                ["-framework", framework]
            }
        case "unsafeFlags":
            return setting.values
        default:
            return []
        }
    }

    /// A Swift define reaches clang too, the way SwiftPM passes it.
    private static func define(_ name: String) -> [String] {
        ["-D\(name)", "-Xcc", "-D\(name)"]
    }

    /// Settings as one list plus one `select` per trait condition.
    ///
    /// One `select` per condition rather than one with every key: two traits can
    /// be on at once, and a `select` whose keys both match is an error rather
    /// than both lists.
    func grouped(
        _ settings: [SwiftPM.Setting],
        in package: SwiftPM.Package,
        always base: [String],
        conditional seeds: [(condition: String, values: [String])] = [],
        flags: (SwiftPM.Setting) -> [String]) -> Starlark.Value?
    {
        var always = base
        var conditions: [String] = []
        var byCondition: [String: [String]] = [:]

        for seed in seeds {
            if byCondition[seed.condition] == nil { conditions.append(seed.condition) }
            byCondition[seed.condition, default: []] += seed.values
        }

        for setting in settings {
            let values = flags(setting)
            guard !values.isEmpty else { continue }

            guard let condition = traitCondition(setting.traits, in: package) else {
                always += values
                continue
            }

            if byCondition[condition] == nil { conditions.append(condition) }
            byCondition[condition, default: []] += values
        }

        return traitValue(
            always,
            conditional: conditions.map { ($0, byCondition[$0] ?? []) })
    }
}

extension Array {
    /// `nil` rather than an empty attribute.
    var nonEmpty: [Element]? {
        isEmpty ? nil : self
    }
}
