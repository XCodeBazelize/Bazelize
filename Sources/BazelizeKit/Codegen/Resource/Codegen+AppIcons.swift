import Foundation
import PathKit
import Starlark
import Xcode

// MARK: - AppIconSelection

/// The icons an application hands to its rule's `app_icons`, and the one of them
/// the bundle shows by default.
struct AppIconSelection {
    /// `ASSETCATALOG_COMPILER_APPICON_NAME`.
    let primary: String
    /// Directory globs, in the order primary first, then alternates by name.
    let patterns: [String]
    /// The primary is the only icon and an `.appiconset`: the rule needs nothing
    /// beyond the attribute, as it never did.
    let isLegacyPrimaryOnly: Bool

    var appIcons: Starlark.Value {
        Starlark.glob(patterns)
    }

    var primaryAppIcon: Starlark.Value? {
        isLegacyPrimaryOnly ? nil : .string(primary)
    }
}

extension Target {
    /// `app_icons` globs would fail analysis on a catalog without the icon set
    /// (`glob` disallows empty matches), and targets commonly carry several
    /// catalogs — SwiftUI previews add one — so only icons found on disk are named.
    ///
    /// - The primary is `ASSETCATALOG_COMPILER_APPICON_NAME`: an Icon Composer
    ///   `.icon` of that name wherever the target keeps it, plus a same-named
    ///   `.appiconset` when provided for older deployment targets.
    /// - Alternates are the names in `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES`
    ///   and, when `ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS` is `YES`,
    ///   every other icon the target owns. Absent and explicitly empty or `NO` both
    ///   select none.
    /// - macOS keeps the primary `.appiconset` alone: its rule takes neither `.icon`
    ///   bundles nor alternates here.
    func appIconSelection(project: borrowing Project) -> AppIconSelection? {
        guard let primary = prefer(\.assetCatalog.appIconName) else { return nil }

        let workspace = Path(project.workspacePath)
        func onDisk(_ label: String) -> Path {
            workspace + (label.delete(prefix: "Sources/") ?? label)
        }

        let isMac = platformSDK == .macOS
        var composerIcons: [String: String] = [:]
        for label in resources where !isMac && label.hasSuffix(".icon") && onDisk(label).isDirectory {
            let name = Path(label).lastComponentWithoutExtension
            if composerIcons[name] == nil { composerIcons[name] = label }
        }

        var catalogIcons: [String: [String]] = [:]
        for catalog in assets {
            let sets = (try? onDisk(catalog).children()) ?? []
            for set in sets where set.extension == "appiconset" && set.isDirectory {
                catalogIcons[set.lastComponentWithoutExtension, default: []].append(catalog)
            }
        }

        func patterns(for name: String) -> [String] {
            let composer = composerIcons[name].map { ["\($0)/**"] } ?? []
            let legacy = (catalogIcons[name] ?? []).map { "\($0)/\(name).appiconset/**" }
            return composer + legacy
        }

        let primaryPatterns = patterns(for: primary)
        guard !primaryPatterns.isEmpty else { return nil }

        var alternates: [String] = []
        if !isMac {
            if prefer(\.assetCatalog.includeAllAppIconAssets) == true {
                alternates += composerIcons.keys
                alternates += catalogIcons.keys
            }
            alternates += prefer(\.assetCatalog.alternateAppIconNames) ?? []
        }
        let alternatePatterns = Set(alternates).subtracting([primary]).sorted().flatMap(patterns(for:))

        return AppIconSelection(
            primary: primary,
            patterns: primaryPatterns + alternatePatterns,
            isLegacyPrimaryOnly: composerIcons[primary] == nil && alternatePatterns.isEmpty)
    }

    func appIcons(project: borrowing Project) -> Starlark.Value? {
        appIconSelection(project: project)?.appIcons
    }
}
