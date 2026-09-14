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
        return Array(Set(projectHeaders + siblings).subtracting(module)).sorted()
    }

    func headerIncludes(project: Project) -> [String] {
        let all = moduleHeaderFiles(project: project) + internalHeaderFiles(project: project)
        let directories = all.map { header in
            Path(header).parent().string
        }

        /// "." keeps a public header reachable by its own relative path.
        /// https://github.com/bazelbuild/bazel/issues/92
        return Array(Set(directories + ["."])).sorted()
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
