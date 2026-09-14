import Foundation

// MARK: - Bazel.Roadmap

extension Bazel {
    struct Roadmap {
        let output: Path
        let project: Project

        func prepare() throws {
            try? output.delete()
            try output.mkpath()
            try linkPackageResolvedIfPresent(project: project)
            try preparePrebuiltFiles(project: project)

            let targetsRoot = output + "Targets"
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
            for relativePath in target.pathsForRoadmapTree {
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
    fileprivate var pathsForRoadmapTree: [String] {
        let allFiles = files.sources + files.headers + files.resources + files.copyFiles + files.others
        let candidates = allFiles.compactMap(\.roadmapRelativePath).sorted {
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
