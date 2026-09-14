import Foundation
import PathKit
import XCode2

/// Headers Xcode resolves through its implicit header map.
///
/// Xcode builds a header map covering every header in the target, so
/// `#import "Other.h"` works no matter which directory the header lives in and
/// whether it belongs to a build phase at all. Bazel resolves includes by path,
/// so those headers have to be declared as inputs and their directories exposed
/// as include paths.
extension Target {
    // MARK: Internal

    /// Headers that belong in the module: Xcode only publishes the ones flagged
    /// `Public` or `Private` in the Headers phase, and modularizing the rest breaks
    /// the module build (project headers routinely pull in C++ or private SDK code).
    func moduleHeaderFiles(project _: Project) -> [String] {
        let exported = exportedHeaders
        /// Targets that publish nothing still need their headers reachable, so fall
        /// back to treating them all as module headers.
        return exported.isEmpty ? Array(Set(headers)).sorted() : exported.sorted()
    }

    /// Headers that are compile inputs only.
    func internalHeaderFiles(project: Project) -> [String] {
        let module = Set(moduleHeaderFiles(project: project))
        let siblings = siblingHeaderPaths(project: project).map { "Sources/\($0)" }
        let searched = searchPathHeaderFiles(project: project)
        return Array(Set(projectHeaders + siblings + searched).subtracting(module)).sorted()
    }

    /// Headers reachable only through `HEADER_SEARCH_PATHS`.
    ///
    /// Bazel sandboxes compile actions, so an include path is useless unless the
    /// headers behind it are declared inputs.
    func searchPathHeaderFiles(project: Project) -> [String] {
        let workspace = Path(project.workspacePath)

        return headerSearchPaths(project: project).flatMap { directory -> [String] in
            let root = workspace + directory
            guard root.isDirectory, let children = try? root.recursiveChildren() else { return [] }

            return children
                .filter(\.isHeader)
                .compactMap { child -> String? in
                    let absolute = child.absolute().string
                    let prefix = root.absolute().string + "/"
                    guard absolute.hasPrefix(prefix) else { return nil }
                    return "Sources/\(directory)/\(absolute.dropFirst(prefix.count))"
                }
        }
    }

    func headerIncludes(project: Project) -> [String] {
        let all = moduleHeaderFiles(project: project) + internalHeaderFiles(project: project)
        let directories = all.map { header in
            Path(header).parent().string
        } + headerSearchPaths(project: project).map { path in
            "Sources/\(path)"
        } + frameworkStyleIncludes(project: project)

        /// "." keeps a public header reachable by its own relative path.
        /// https://github.com/bazelbuild/bazel/issues/92
        return Array(Set(directories + ["."])).sorted()
    }

    /// Include paths that make `#import <Module/Header.h>` resolve.
    ///
    /// Xcode publishes a framework's headers under a directory named after the
    /// framework, so dependents import them that way. In the generated tree the
    /// headers keep their project-relative layout, which already has such a
    /// directory whenever the sources live in a folder named after the module — the
    /// path above it is what the compiler needs.
    private func frameworkStyleIncludes(project: Project) -> [String] {
        moduleHeaderFiles(project: project).compactMap { header in
            let directory = Path(header).parent()
            guard directory.lastComponent == codegenModuleName || directory.lastComponent == name else {
                return nil
            }
            let parent = directory.parent().string
            return parent == "." ? nil : parent
        }
    }

    /// The same include paths, spelled for `swiftc`'s clang importer.
    ///
    /// Bazel resolves the `includes` attribute relative to the package, raw `-I`
    /// flags relative to the execution root.
    func swiftIncludeCopts(project: Project) -> [String] {
        headerIncludes(project: project)
            .filter { $0 != "." }
            .flatMap { directory in
                ["-Xcc", "-ITargets/\(name)/\(directory)"]
            }
    }

    /// Workspace-relative `HEADER_SEARCH_PATHS` entries.
    ///
    /// Xcode resolves them against the project; anything outside the workspace
    /// cannot be materialized into the target tree and is dropped.
    func headerSearchPaths(project: Project) -> [String] {
        let workspace = Path(project.workspacePath).absolute().string

        return (prefer(\.headerSearchPaths) ?? []).compactMap { path -> String? in
            /// Xcode quotes segments and allows `$(SETTING:modifier)`; a path that
            /// still carries either cannot be resolved to a directory here.
            let unquoted = path.replacingOccurrences(of: "\"", with: "")
            guard !unquoted.contains("$") else { return nil }

            let normalized = Path(unquoted).normalize().string
            guard normalized != "." else { return nil }

            if !normalized.hasPrefix("/") {
                return normalized
            }

            let prefix = workspace + "/"
            guard normalized.hasPrefix(prefix) else { return nil }
            return String(normalized.dropFirst(prefix.count))
        }
    }

    /// Workspace-relative headers that sit next to the target's compiled sources.
    func siblingHeaderPaths(project: Project) -> [String] {
        let workspace = Path(project.workspacePath)

        return sourceDirectories.flatMap { directory -> [String] in
            let sourceDirectory = directory.isEmpty ? workspace : workspace + directory
            guard sourceDirectory.isDirectory, let children = try? sourceDirectory.children() else {
                return []
            }

            return children
                .filter(\.isHeader)
                .map { child in
                    directory.isEmpty ? child.lastComponent : "\(directory)/\(child.lastComponent)"
                }
        }
    }

    /// Bazel picks the clang dialect from the file extension, Xcode from the
    /// declared file type. When every C-family source in the target is
    /// Objective-C++ but not named `.mm`, the dialect has to be forced.
    var clangDialectCopts: [String] {
        let clangSources = srcs_c + srcs_cpp + srcs_objc + srcs_objcpp
        guard !clangSources.isEmpty else { return [] }
        guard srcs_objcpp.count == clangSources.count else { return [] }
        guard srcs_objcpp.contains(where: { !$0.hasSuffix(".mm") }) else { return [] }

        return ["-x", "objective-c++"]
    }

    // MARK: Private

    /// Workspace-relative directories holding the target's compiled sources.
    private var sourceDirectories: Set<String> {
        Set(
            srcs.map { source in
                let relative = source.delete(prefix: "Sources/") ?? source
                let directory = Path(relative).parent().string
                return directory == "." ? "" : directory
            })
    }
}

extension Path {
    var isHeader: Bool {
        guard let ext = `extension`?.lowercased() else { return false }
        return ["h", "hh", "hpp", "hxx"].contains(ext)
    }
}
