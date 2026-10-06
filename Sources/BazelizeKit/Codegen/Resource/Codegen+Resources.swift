import BazelRules
import Foundation
import PathKit
import Starlark
import Xcode

extension Target {
    static let resourceGroupName = "Resources"
    static let structuredResourceGroupName = "ResourceFolders"

    /// Everything Xcode's Resources build phase copies into the bundle, minus what a
    /// dedicated rule attribute already owns: an asset catalog, a `.strings` table
    /// and an app icon set.
    ///
    /// Without this a generated app links and bundles, but ships no nib and no
    /// localization, so it dies the moment it is launched. It is the only place a
    /// nib or a storyboard is declared: passing one through the library's `data` as
    /// well makes two rules compile it to the same path.
    func generateResources(_ builder: CodeBuilder, _ kit: Kit) {
        let resources = resourceFiles(project: kit.project)
        if !resources.isEmpty {
            builder.call(
                Rules.Builtin.Call.filegroup(
                    name: Self.resourceGroupName,
                    srcs: Starlark.paths(resources),
                    visibility: .private))
        }

        let folders = resourceFolders(project: kit.project)
        guard !folders.isEmpty else { return }

        builder.load(loadableRule: Rules.Apple.Resources.apple_resource_group)
        builder.call(
            Rules.Apple.Resources.Call.apple_resource_group(
                name: Self.structuredResourceGroupName,
                strip_structured_resources_prefixes: Array(Set(folders.map(\.parent))).sorted(),
                structured_resources: Starlark.paths(folders.map { "\($0.path)/**" }),
                visibility: .private))
    }

    /// The bundle rule's `resources`: the groups above plus the asset catalog.
    func bundleResources(project: Project?) -> [Starlark.Label] {
        var labels: [Starlark.Label] = []
        if let project, !resourceFiles(project: project).isEmpty {
            labels.append(.named(":\(Self.resourceGroupName)"))
        }
        if let project, !resourceFolders(project: project).isEmpty {
            labels.append(.named(":\(Self.structuredResourceGroupName)"))
        }
        if !assets.isEmpty {
            labels.append(.named(":Assets"))
        }
        return labels
    }

    // MARK: Private

    /// A folder reference: Xcode copies the directory whole, keeping its name and
    /// everything under it. Flattening one into `resources` places every file it
    /// holds at the bundle's root, which is both wrong and — for two themes that
    /// each ship an `Info.plist` — rejected outright.
    private struct ResourceFolder {
        let path: String
        let parent: String
    }

    private func resourceFiles(project: Project) -> [String] {
        Array(Set(classifiedResources(project: project).files)).sorted()
    }

    private func resourceFolders(project: Project) -> [ResourceFolder] {
        let folders = classifiedResources(project: project).folders
        return Array(Set(folders.map(\.path)))
            .sorted()
            .map { .init(path: $0, parent: Path($0).parent().normalize().string) }
    }

    private func classifiedResources(project: Project) -> (files: [String], folders: [ResourceFolder]) {
        let workspace = Path(project.workspacePath)

        var files: [String] = []
        var folders: [ResourceFolder] = []
        for resource in resources {
            guard !Self.ownedResourceExtensions.contains(Path(resource).extension ?? "") else { continue }

            /// The model already addresses a file through the target's `Sources/`
            /// tree; the project is where it is read from.
            let source = workspace + Path(resource.droppingSourcesPrefix)
            guard source.exists else { continue }

            if source.isDirectory {
                folders.append(.init(path: resource, parent: Path(resource).parent().normalize().string))
            } else {
                files.append(resource)
            }
        }

        return (files, folders)
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
