import Foundation

// MARK: - Bazel.Roadmap

extension Bazel {
    struct Roadmap {
        let output: Path
        let project: Project

        /// Only the directories bazelize owns are wiped.
        ///
        /// Deleting the whole output root would take the project itself with it when
        /// no `--output` is given, and otherwise throw away the resolved SwiftPM and
        /// Bazel state that lives next to the generated files.
        func prepare() throws {
            let targetsRoot = output + "Targets"
            let prebuiltRoot = output + "Prebuilt"

            try? targetsRoot.delete()
            try? prebuiltRoot.delete()

            try output.mkpath()
            try linkPackageResolvedIfPresent(project: project)
            try preparePrebuiltFiles(project: project)
            try targetsRoot.mkpath()

            for target in project.targets {
                try prepare(target: target, project: project, targetsRoot: targetsRoot)
            }
        }

        private func prepare(
            target: Target,
            project: Project,
            targetsRoot: Path) throws
        {
            let targetRoot = targetsRoot + target.name
            let sourcesRoot = targetRoot + "Sources"
            let generatedRoot = targetRoot + "Generated"

            try sourcesRoot.mkpath()
            try generatedRoot.mkpath()

            var materializedDirectories = Set<String>()
            for relativePath in target.pathsForRoadmapTree(project: project) {
                let normalizedPath = relativePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                let hasMaterializedAncestor = materializedDirectories.contains { existing in
                    normalizedPath == existing || normalizedPath.hasPrefix(existing + "/")
                }
                guard !hasMaterializedAncestor else { continue }

                let source = Path(project.workspacePath) + relativePath
                guard source.exists else { continue }
                guard !source.isSelfReferentialSymlink else { continue }

                let destination = sourcesRoot + relativePath
                try materialize(source: source, destination: destination)
                if source.isDirectory {
                    materializedDirectories.insert(normalizedPath)
                }
            }

            try prepareSiblingHeaders(target: target, project: project, sourcesRoot: sourcesRoot)
            try prepareModuleHeaders(target: target, project: project, targetRoot: targetRoot)
            try prepareDefinesHeader(target: target, targetRoot: targetRoot)
            try prepareEntitlements(target: target, project: project, targetRoot: targetRoot)
            try prepareCopiedFiles(target: target, project: project, targetRoot: targetRoot)
        }

        /// Files a copy phase places in the bundle, staged under the destination the
        /// phase names: the rules address a resource by its path, and Xcode copies
        /// the same file name to more than one destination.
        private func prepareCopiedFiles(target: Target, project: Project, targetRoot: Path) throws {
            let workspace = Path(project.workspacePath)

            for group in target.copiedFileGroups(project: project) {
                let destination = targetRoot + Target.copyFilesRoot + group.subdirectory

                for file in group.files {
                    let relativePath = file.delete(prefix: "Sources/") ?? file
                    let source = workspace + relativePath
                    guard source.exists else { continue }

                    try destination.mkpath()
                    try materialize(source: source, destination: destination + Path(relativePath).lastComponent)
                }
            }
        }

        /// The entitlements Xcode signs with, expanded: rules_apple substitutes no
        /// build setting, and its `plisttool` fails on a variable it cannot resolve.
        private func prepareEntitlements(target: Target, project: Project, targetRoot: Path) throws {
            guard
                let relativePath = target.entitlementsPath,
                let content = target.entitlementsContent(project: project)
            else {
                return
            }

            let destination = targetRoot + relativePath
            try destination.parent().mkpath()
            try destination.write(content)
        }

        /// `GCC_PREPROCESSOR_DEFINITIONS` as a header the compiles force-include.
        private func prepareDefinesHeader(target: Target, targetRoot: Path) throws {
            guard let relativePath = target.definesHeader else { return }

            let definitions = (target.prefer(\.preprocessorDefinitions) ?? []).map { definition in
                guard let separator = definition.firstIndex(of: "=") else {
                    return "#define \(definition) 1"
                }
                let key = definition[..<separator]
                let value = definition[definition.index(after: separator)...]
                return "#define \(key) \(value)"
            }

            let destination = targetRoot + relativePath
            try destination.parent().mkpath()
            try destination.write((["// Generated using Bazelize"] + definitions).withNewLine)
        }

        /// Xcode copies a target's published headers into one flat directory inside
        /// the product, which is what makes `#import <Module/Any.h>` work regardless
        /// of where the header lives. The generated tree mirrors that directory.
        private func prepareModuleHeaders(
            target: Target,
            project: Project,
            targetRoot: Path) throws
        {
            let workspace = Path(project.workspacePath)
            let moduleRoot = targetRoot + Target.moduleHeaderRoot + target.codegenModuleName
            let headers = target.moduleHeaderFiles(project: project)
            guard !headers.isEmpty else { return }

            try moduleRoot.mkpath()

            for header in headers {
                let relativePath = header.delete(prefix: "Sources/") ?? header
                let source = workspace + relativePath
                guard source.exists, !source.isSelfReferentialSymlink else { continue }

                let destination = moduleRoot + source.lastComponent
                try materialize(source: source, destination: destination)
            }
        }

        /// Xcode's implicit header map makes every header in the target reachable by
        /// file name, even when it belongs to no build phase. Bazel needs the file
        /// declared, so headers next to the target's compiled sources come along.
        private func prepareSiblingHeaders(
            target: Target,
            project: Project,
            sourcesRoot: Path) throws
        {
            let workspace = Path(project.workspacePath)

            for relativePath in target.siblingHeaderPaths(project: project) {
                let source = workspace + relativePath
                guard source.exists, !source.isSelfReferentialSymlink else { continue }

                let destination = sourcesRoot + relativePath
                guard !destination.exists, !destination.isSymlink else { continue }

                try materialize(source: source, destination: destination)
            }
        }

        private func preparePrebuiltFiles(project: XCode2.XCode.Project) throws {
            let prebuiltRoot = output + "Prebuilt"
            try prebuiltRoot.mkpath()

            for file in project.prebuiltFiles {
                guard let relativePath = file.path, !relativePath.isEmpty else { continue }
                let source = Path(project.workspacePath) + relativePath
                guard source.exists else { continue }
                guard !source.isSelfReferentialSymlink else { continue }

                let destination = prebuiltRoot + Path(relativePath).lastComponent
                try replaceIfNeeded(at: destination)
                try destination.symlink(source)
            }
        }

        private func linkPackageResolvedIfPresent(project: XCode2.XCode.Project) throws {
            let source = Path(project.workspacePath) + "Package.resolved"
            guard source.exists else { return }

            let destination = output + "Package.resolved"
            try replaceIfNeeded(at: destination)
            try destination.symlink(source)
        }

        private func replaceIfNeeded(at path: Path) throws {
            guard path.exists || path.isSymlink else { return }
            try path.delete()
        }

        private func materialize(source: Path, destination: Path) throws {
            guard !source.isRoadmapIgnoredFile else { return }

            if source.isDirectory {
                if destination.isSymlink {
                    try destination.delete()
                }
                if !destination.exists {
                    try destination.mkpath()
                }
                for child in try source.children() {
                    guard !child.isSelfReferentialSymlink else { continue }
                    try materialize(source: child, destination: destination + child.lastComponent)
                }
                return
            }

            try destination.parent().mkpath()
            try replaceIfNeeded(at: destination)
            try destination.symlink(source)
        }
    }
}

extension XCode2.XCode.Target {
    fileprivate func pathsForRoadmapTree(project: Project) -> [String] {
        let allFiles = files.sources + files.headers + files.resources + files.copyFiles + files.others
        let candidates = (allFiles.compactMap(\.roadmapRelativePath) + settingReferencedPaths + headerSearchPaths(project: project)).sorted {
            let lhsDepth = $0.split(separator: "/").count
            let rhsDepth = $1.split(separator: "/").count
            if lhsDepth == rhsDepth {
                return $0 < $1
            }
            return lhsDepth < rhsDepth
        }

        var result: [String] = []
        var seen = Set<String>()

        for path in candidates where seen.insert(path).inserted {
            let hasAncestor = result.contains { existing in
                path == existing || path.hasPrefix(existing + "/")
            }
            guard !hasAncestor else { continue }
            result.append(path)
        }

        return result
    }

    /// Files Xcode reaches through build settings instead of a build phase; the
    /// bridging header and entitlements are rule inputs, so they need to exist in
    /// the target's `Sources/` tree.
    fileprivate var settingReferencedPaths: [String] {
        [
            prefer(\.bridgingHeader),
            prefer(\.prefixHeader),
            metadata.entitlements,
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty && !$0.hasPrefix("/") }
        .map { Path($0).normalize().string }
    }
}

extension XCode2.XCode.Project {
    fileprivate var prebuiltFiles: [XCode2.XCode.File] {
        let all = targets.flatMap { target in
            target.files.frameworks.filter { $0.label?.hasPrefix("//Prebuilt:") == true }
        }

        var seen = Set<String>()
        return all.filter { file in
            guard let path = file.path else { return false }
            return seen.insert(path).inserted
        }
    }
}

extension XCode2.XCode.File {
    fileprivate var roadmapRelativePath: String? {
        if let path, !path.isEmpty {
            return path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }
        return nil
    }
}

extension Path {
    fileprivate var isSelfReferentialSymlink: Bool {
        guard isSymlink else { return false }
        guard let destination = try? symlinkDestination().absolute() else { return false }
        return destination == absolute()
    }

    fileprivate var isRoadmapIgnoredFile: Bool {
        switch lastComponent {
        case "BUILD", "BUILD.bazel":
            return true
        default:
            return false
        }
    }
}
