import BazelRules
import Foundation
import PathKit
import Starlark
import Xcode

extension Target {
    static let resourceGroupName = "Resources"

    /// Everything Xcode's Resources build phase copies into the bundle, minus what a
    /// dedicated rule attribute already owns: an asset catalog, a `.strings` table
    /// and an app icon set.
    ///
    /// Without this a generated app links and bundles, but ships no nib and no
    /// localization, so it dies the moment it is launched. It is the only place a
    /// nib or a storyboard is declared: passing one through the library's `data` as
    /// well makes two rules compile it to the same path.
    func generateResources(_ builder: CodeBuilder, _ kit: Kit) {
        let patterns = resourcePatterns(project: kit.project)
        guard !patterns.isEmpty else { return }

        builder.call(
            Rules.Builtin.Call.filegroup(
                name: Self.resourceGroupName,
                srcs: Starlark.glob(patterns),
                visibility: .private))
    }

    /// The bundle rule's `resources`: the group above plus the asset catalog.
    func bundleResources(project: Project?) -> [Starlark.Label] {
        var labels: [Starlark.Label] = []
        if let project, !resourcePatterns(project: project).isEmpty {
            labels.append(.named(":\(Self.resourceGroupName)"))
        }
        if !assets.isEmpty {
            labels.append(.named(":Assets"))
        }
        return labels
    }

    // MARK: Private

    /// A resource is either a file or a folder reference — Xcode copies a folder
    /// whole — so a directory becomes a recursive glob.
    private func resourcePatterns(project: Project) -> [String] {
        let workspace = Path(project.workspacePath)

        let patterns = resources.compactMap { resource -> String? in
            guard !Self.ownedResourceExtensions.contains(Path(resource).extension ?? "") else { return nil }

            /// The model already addresses a file through the target's `Sources/`
            /// tree; the project is where it is read from.
            let source = workspace + Path(resource.droppingSourcesPrefix)
            guard source.exists else { return nil }
            return source.isDirectory ? "\(resource)/**" : resource
        }

        return Array(Set(patterns)).sorted()
    }

    /// Resources another attribute of the same rule already carries: passing them
    /// twice makes rules_apple fail on a duplicated bundle path.
    ///
    /// An Icon Composer `.icon` bundle is dropped for a different reason: `actool`
    /// refuses one whose `icon.json` is a symlink, and every file a Bazel action
    /// sees is a symlink. Leaving it in the resources also makes rules_apple reject
    /// the `.appiconset` the same project still ships.
    private static let ownedResourceExtensions: Set<String> = [
        "icon",
        "intentdefinition",
        "strings",
        "xcassets"
    ]
}

extension String {
    fileprivate var droppingSourcesPrefix: String {
        hasPrefix("Sources/") ? String(dropFirst("Sources/".count)) : self
    }
}
