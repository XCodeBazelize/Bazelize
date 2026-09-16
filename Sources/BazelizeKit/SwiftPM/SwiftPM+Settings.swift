//
//  SwiftPM+Settings.swift
//
//
//  `SwiftSetting` and `LinkerSetting` as compiler and linker flags.
//

import Foundation

extension SwiftPM.Generator {
    /// What the target compiles with, beyond the defaults.
    ///
    /// SwiftPM hands these to `swiftc` directly, so they are copts rather than
    /// anything the rules model: a `defines` attribute would re-tokenize a value
    /// and a feature is not a flag the rules know.
    func copts(of target: SwiftPM.PackageTarget) -> [String] {
        target.settings.flatMap { setting -> [String] in
            guard setting.tool == "swift", let name = setting.name else { return [] }

            switch name {
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
                guard let mode = setting.values.first else { return [] }
                return ["-cxx-interoperability-mode=\(mode)"]
            case "unsafeFlags":
                return setting.values
            default:
                return []
            }
        }
    }

    /// `SWIFT_PACKAGE` is what a package's own sources test for; SwiftPM defines it
    /// for every target it builds.
    func defines(of target: SwiftPM.PackageTarget) -> [String] {
        let declared = target.settings.compactMap { setting -> [String]? in
            guard setting.tool == "swift", setting.name == "define" else { return nil }
            return setting.values
        }.flatMap { $0 }

        return ["SWIFT_PACKAGE"] + declared
    }

    /// A package can name a system library or framework it needs; nothing else in
    /// the graph knows about it.
    func linkopts(of target: SwiftPM.PackageTarget) -> [String] {
        target.settings.flatMap { setting -> [String] in
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
    }
}

extension Array {
    /// `nil` rather than an empty attribute.
    var nonEmpty: [Element]? {
        isEmpty ? nil : self
    }
}
