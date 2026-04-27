import Foundation
import PathKit

public extension XCode {
    struct RoadmapTreeBuilder {
        public let output: Path

        public init(output: Path) {
            self.output = output
        }

        public func build(project: XCode.Project) throws {
            try output.mkpath()
            try write(path: output + "BUILD", contents: rootBuildContents(project: project))
            try write(path: output + "MODULE.bazel", contents: moduleContents(project: project))
            try write(path: output + "Package.swift", contents: packageSwiftContents(project: project))
            try linkPackageResolvedIfPresent(project: project)

            let prebuilt = output + "Prebuilt"
            try prebuilt.mkpath()
            try materializePrebuiltFiles(project: project, prebuiltRoot: prebuilt)
            try write(path: prebuilt + "BUILD", contents: prebuiltBuildContents(project: project))

            for target in project.targets {
                try build(target: target, project: project)
            }
        }

        private func build(target: XCode.Target, project: XCode.Project) throws {
            let targetRoot = output + target.name
            let sourcesRoot = targetRoot + "Sources"
            let generatedRoot = targetRoot + "Generated"

            try sourcesRoot.mkpath()
            try generatedRoot.mkpath()
            try writeGeneratedFiles(target: target, generatedRoot: generatedRoot)
            try write(path: targetRoot + "BUILD", contents: buildFileContents(target: target, project: project))

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

        private func rootBuildContents(project: XCode.Project) -> String {
            if project.configs.isEmpty {
                return ""
            }

            let configSettings = project.configs.keys.sorted().map { config in
                """
                config_setting(
                    name = "\(config)",
                    values = {"compilation_mode": "\(config.lowercased())"},
                )
                """
            }.joined(separator: "\n\n")

            return configSettings + "\n"
        }

        private func prebuiltBuildContents(project: XCode.Project) -> String {
            let xcframeworks = project.prebuiltXcframeworks
            guard !xcframeworks.isEmpty else { return "" }

            let load = #"load("@build_bazel_rules_apple//apple:apple.bzl", "apple_dynamic_xcframework_import")"#
            let rules = xcframeworks.compactMap { file -> String? in
                guard let path = file.path, !path.isEmpty else { return nil }
                let name = Path(path).lastComponentWithoutExtension
                return """
                apple_dynamic_xcframework_import(
                    name = "\(name)",
                    xcframework_imports = glob([
                        "\(path)/**",
                    ]),
                    visibility = ["//visibility:public"],
                )
                """
            }.joined(separator: "\n\n")

            return load + "\n\n" + rules + "\n"
        }

        private func moduleContents(project: XCode.Project) -> String {
            let repos = swiftPackageRepoNames(project: project)
            let useRepoItems = (["swift_deps"] + repos.map { #""\#($0)""# }).joined(separator: ",\n    ")

            return """
            module(name = "example", version = "0.0.1")

            bazel_dep(name = "bazel_skylib", version = "1.9.0")
            bazel_dep(name = "rules_cc", version = "0.2.17")
            bazel_dep(name = "rules_apple", version = "4.5.0", repo_name = "build_bazel_rules_apple")
            bazel_dep(name = "rules_swift", version = "3.5.0", repo_name = "build_bazel_rules_swift")
            bazel_dep(name = "rules_swift_package_manager", version = "1.13.0")

            swift_deps = use_extension(
                "@rules_swift_package_manager//:extensions.bzl",
                "swift_deps",
            )
            swift_deps.from_package(
                declare_swift_deps_info = True,
                resolved = "//:Package.resolved",
                swift = "//:Package.swift",
            )
            use_repo(
                \(useRepoItems)
            )
            """
        }

        private func packageSwiftContents(project: XCode.Project) -> String {
            let remoteDeps = project.packages.remote.compactMap(packageDependencyLine(remote:))
            let localDeps = project.roadmapLocalPackages.map { local in
                let path = local.packagePath.absolute().string
                return #"        .package(path: "\#(path)"),"#
            }
            let deps = (remoteDeps + localDeps).joined(separator: "\n")

            return """
            // swift-tools-version: 5.7
            import PackageDescription

            let package = Package(
                name: "RoadmapPackages",
                dependencies: [
            \(deps)
                ]
            )
            """
        }

        private func buildFileContents(target: XCode.Target, project: XCode.Project) -> String {
            var sections: [String] = []
            var loads: [String: Set<String>] = [:]

            if target.hasSwiftSources {
                loads["@build_bazel_rules_swift//swift:swift.bzl", default: []].insert("swift_library")
                sections.append(swiftLibraryContents(target: target, project: project))
            } else if target.hasObjcSources || target.hasHeaders {
                loads["@rules_cc//cc:defs.bzl", default: []].insert("objc_library")
                sections.append(objcLibraryContents(target: target, project: project))
            }

            switch target.roadmapKind {
            case .application:
                loads["@build_bazel_rules_apple//apple:ios.bzl", default: []].insert("ios_application")
                sections.append(iosApplicationContents(target: target, project: project))
            case .framework:
                loads["@build_bazel_rules_apple//apple:ios.bzl", default: []].insert("ios_framework")
                sections.append(iosFrameworkContents(target: target, project: project))
            case .staticLibrary:
                sections.append(staticLibraryAliasContents(target: target))
            case .other:
                if sections.isEmpty {
                    sections.append("# Unsupported target type: \(target.productType ?? "unknown")")
                }
            }

            let loadLines = loads.keys.sorted().map { label in
                let rules = loads[label, default: []].sorted().map { #""\#($0)""# }.joined(separator: ", ")
                return #"load("\#(label)", \#(rules))"#
            }

            return (loadLines + sections).joined(separator: "\n\n") + "\n"
        }

        private func swiftLibraryContents(target: XCode.Target, project: XCode.Project) -> String {
            let deps = quotedList(
                target.targetLibraryDeps(project: project) +
                target.swiftPackageProductLabels(project: project) +
                target.prebuiltDependencyLabels
            )
            return """
            swift_library(
                name = "\(target.name)_library",
                module_name = "\(target.moduleNameForRoadmap)",
                srcs = glob(["Sources/**/*.swift"], allow_empty = True),
                deps = \(deps),
                visibility = ["//visibility:public"],
            )
            """
        }

        private func objcLibraryContents(target: XCode.Target, project: XCode.Project) -> String {
            let hdrs = #"glob(["Sources/**/*.h", "Sources/**/*.hpp"], allow_empty = True)"#
            let srcs = #"glob(["Sources/**/*.m", "Sources/**/*.mm", "Sources/**/*.c", "Sources/**/*.cc", "Sources/**/*.cpp"], allow_empty = True)"#
            let deps = quotedList(
                target.targetLibraryDeps(project: project) +
                target.swiftPackageProductLabels(project: project) +
                target.prebuiltDependencyLabels
            )

            return """
            objc_library(
                name = "\(target.name)_objc",
                module_name = "\(target.moduleNameForRoadmap)",
                srcs = \(srcs),
                hdrs = \(hdrs),
                includes = ["."],
                deps = \(deps),
                visibility = ["//visibility:private"],
            )

            alias(
                name = "\(target.name)_library",
                actual = ":\(target.name)_objc",
                visibility = ["//visibility:public"],
            )
            """
        }

        private func iosApplicationContents(target: XCode.Target, project: XCode.Project) -> String {
            let deps = quotedList([":\(target.name)_library"] + target.prebuiltDependencyLabels)
            let sdkFrameworks = quotedList(target.dependencies.sdkFrameworks)
            let resources = #"glob(["Sources/**"], exclude = ["Sources/**/*.swift", "Sources/**/*.h", "Sources/**/*.hpp", "Sources/**/*.m", "Sources/**/*.mm", "Sources/**/*.c", "Sources/**/*.cc", "Sources/**/*.cpp"], allow_empty = True)"#

            var lines: [String] = [
                "ios_application(",
                #"    name = "\#(target.name)","#,
                #"    bundle_id = "\#(target.metadata.bundleID ?? "com.example.\(target.name)")","#,
            ]

            if let minimumOS = target.metadata.deploymentTargets["iOS"] {
                lines.append(#"    minimum_os_version = "\#(minimumOS)","#)
            }
            if let families = target.appleFamiliesLiteral {
                lines.append("    families = \(families),")
            }

            lines.append("    deps = \(deps),")
            lines.append(#"    infoplists = ["Generated/Info.plist"],"#)
            if sdkFrameworks != "[]" {
                lines.append("    sdk_frameworks = \(sdkFrameworks),")
            }
            lines.append("    resources = \(resources),")
            lines.append(#"    visibility = ["//visibility:public"],"#)
            lines.append(")")
            return lines.joined(separator: "\n")
        }

        private func iosFrameworkContents(target: XCode.Target, project: XCode.Project) -> String {
            let deps = quotedList([":\(target.name)_library"] + target.prebuiltDependencyLabels)
            let resources = #"glob(["Sources/**"], exclude = ["Sources/**/*.swift", "Sources/**/*.h", "Sources/**/*.hpp", "Sources/**/*.m", "Sources/**/*.mm", "Sources/**/*.c", "Sources/**/*.cc", "Sources/**/*.cpp"], allow_empty = True)"#

            var lines: [String] = [
                "ios_framework(",
                #"    name = "\#(target.name)","#,
            ]

            if let bundleID = target.metadata.bundleID {
                lines.append(#"    bundle_id = "\#(bundleID)","#)
            }
            if let minimumOS = target.metadata.deploymentTargets["iOS"] {
                lines.append(#"    minimum_os_version = "\#(minimumOS)","#)
            }
            if let families = target.appleFamiliesLiteral {
                lines.append("    families = \(families),")
            }

            lines.append("    deps = \(deps),")
            lines.append(#"    infoplists = ["Generated/Info.plist"],"#)
            lines.append("    resources = \(resources),")
            lines.append(#"    visibility = ["//visibility:public"],"#)
            lines.append(")")
            return lines.joined(separator: "\n")
        }

        private func staticLibraryAliasContents(target: XCode.Target) -> String {
            """
            alias(
                name = "\(target.name)",
                actual = ":\(target.name)_library",
                visibility = ["//visibility:public"],
            )
            """
        }

        private func packageDependencyLine(remote: XCode.RemotePackage) -> String? {
            guard let url = remote.repositoryURL else { return nil }

            if let requirement = remote.requirement {
                if let version = requirement.wrappedValue(prefix: "upToNextMajorVersion(") {
                    return #"        .package(url: "\#(url)", from: "\#(version)"),"#
                }
                if let version = requirement.wrappedValue(prefix: "upToNextMinorVersion(") {
                    return #"        .package(url: "\#(url)", .upToNextMinor(from: "\#(version)")),"#
                }
                if let version = requirement.wrappedValue(prefix: "exact(") {
                    return #"        .package(url: "\#(url)", exact: "\#(version)"),"#
                }
                if let branch = requirement.wrappedValue(prefix: "branch(") {
                    return #"        .package(url: "\#(url)", branch: "\#(branch)"),"#
                }
                if let revision = requirement.wrappedValue(prefix: "revision(") {
                    return #"        .package(url: "\#(url)", revision: "\#(revision)"),"#
                }
            }

            return #"        .package(url: "\#(url)", from: "0.0.1"),"#
        }

        private func swiftPackageRepoNames(project: XCode.Project) -> [String] {
            let remote = project.packages.remote.compactMap { package in
                package.repositoryURL.map(repositoryName(url:))
            }
            let local = project.roadmapLocalPackages.map { package in
                repositoryName(path: package.packagePath.lastComponent)
            }
            return Array(Set(remote + local)).sorted()
        }

        private func linkPackageResolvedIfPresent(project: XCode.Project) throws {
            let source = Path(project.workspacePath) + "Package.resolved"
            guard source.exists else { return }

            let destination = output + "Package.resolved"
            try replaceIfNeeded(at: destination)
            try destination.symlink(source)
        }

        private func write(path: Path, contents: String) throws {
            try path.parent().mkpath()
            try contents.write(toFile: path.string, atomically: true, encoding: .utf8)
        }

        private func replaceIfNeeded(at path: Path) throws {
            guard path.exists || path.isSymlink else { return }
            try path.delete()
        }

        private func materialize(source: Path, destination: Path) throws {
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

        private func materializePrebuiltFiles(project: XCode.Project, prebuiltRoot: Path) throws {
            for file in project.prebuiltXcframeworks {
                guard let relativePath = file.path, !relativePath.isEmpty else { continue }
                let source = Path(project.workspacePath) + relativePath
                guard source.exists else { continue }
                guard !source.isSelfReferentialSymlink else { continue }

                let destination = prebuiltRoot + relativePath
                try materialize(source: source, destination: destination)
            }
        }

        private func repositoryName(url: String) -> String {
            repositoryName(module: Path(url).lastComponentWithoutExtension)
        }

        private func repositoryName(path: String) -> String {
            repositoryName(module: Path(path).lastComponent)
        }

        private func repositoryName(module: String) -> String {
            "swiftpkg_" + sanitize(module.lowercased())
        }

        private func sanitize(_ value: String) -> String {
            value.replacingOccurrences(of: "-", with: "_")
        }

        private func quotedList(_ values: [String]) -> String {
            let all = Array(Set(values)).sorted()
            return "[" + all.map { #""\#($0)""# }.joined(separator: ", ") + "]"
        }

        private func writeGeneratedFiles(target: XCode.Target, generatedRoot: Path) throws {
            switch target.roadmapKind {
            case .application, .framework:
                try write(path: generatedRoot + "Info.plist", contents: generatedInfoPlist(target: target))
            case .staticLibrary, .other:
                break
            }
        }

        private func generatedInfoPlist(target: XCode.Target) -> String {
            let bundleID = target.metadata.bundleID ?? "com.example.\(target.name)"
            let bundleName = target.name
            let packageType: String = switch target.roadmapKind {
            case .application: "APPL"
            case .framework: "FMWK"
            case .staticLibrary, .other: "BNDL"
            }
            return """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>CFBundleIdentifier</key>
                <string>\(bundleID)</string>
                <key>CFBundleName</key>
                <string>\(bundleName)</string>
                <key>CFBundleExecutable</key>
                <string>\(bundleName)</string>
                <key>CFBundleShortVersionString</key>
                <string>1.0</string>
                <key>CFBundlePackageType</key>
                <string>\(packageType)</string>
                <key>CFBundleVersion</key>
                <string>1</string>
            </dict>
            </plist>
            """
        }
    }
}

private extension XCode.Target {
    enum RoadmapKind {
        case application
        case framework
        case staticLibrary
        case other
    }

    var roadmapKind: RoadmapKind {
        switch productType ?? "" {
        case "com.apple.product-type.application":
            return .application
        case "com.apple.product-type.framework":
            return .framework
        case "com.apple.product-type.library.static":
            return .staticLibrary
        default:
            return .other
        }
    }

    var hasSwiftSources: Bool {
        files.sources.contains { $0.fileType == "sourcecode.swift" || ($0.path?.hasSuffix(".swift") ?? false) }
    }

    var hasObjcSources: Bool {
        files.sources.contains {
            let path = $0.path ?? ""
            return path.hasSuffix(".m") || path.hasSuffix(".mm") || path.hasSuffix(".c") || path.hasSuffix(".cc") || path.hasSuffix(".cpp")
        }
    }

    var hasHeaders: Bool {
        !files.headers.isEmpty
    }

    var moduleNameForRoadmap: String {
        let moduleName = metadata.moduleName ?? name
        if moduleName.contains("$(") || moduleName.isEmpty {
            return name
        }
        return moduleName
    }

    var appleFamiliesLiteral: String? {
        guard let raw = selectedSettings["TARGETED_DEVICE_FAMILY"] else { return nil }
        let families = raw
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .compactMap { code -> String? in
                switch code {
                case "1": return "iphone"
                case "2": return "ipad"
                case "3": return "tv"
                case "4": return "watch"
                default: return nil
                }
            }
        guard !families.isEmpty else { return nil }
        return "[" + families.map { #""\#($0)""# }.joined(separator: ", ") + "]"
    }

    var selectedSettings: XCode.BuildSettings {
        if let debug = configs["Debug"] {
            return debug
        }
        if let first = configs.keys.sorted().first, let value = configs[first] {
            return value
        }
        return .init(name: "", setting: [:])
    }

    func targetLibraryDeps(project: XCode.Project) -> [String] {
        dependencies.targets.compactMap { dep in
            guard project.targets.contains(where: { $0.name == dep }) else { return nil }
            return "//\(dep):\(dep)_library"
        }
    }

    func targetBundleDeps(project: XCode.Project) -> [String] {
        dependencies.targets.compactMap { dep in
            guard project.targets.contains(where: { $0.name == dep }) else { return nil }
            return "//\(dep):\(dep)"
        }
    }

    func swiftPackageProductLabels(project: XCode.Project) -> [String] {
        let localRepos = project.localPackageRepoByProduct

        return dependencies.packageProducts.compactMap { product in
            if let package = product.package, !package.isEmpty {
                let repo = "swiftpkg_" + sanitizeRepo(Path(package).lastComponentWithoutExtension.lowercased())
                return "@\(repo)//:\(product.productName)"
            }

            if let repo = localRepos[product.productName] {
                return "@\(repo)//:\(product.productName)"
            }

            return nil
        }
    }

    private func sanitizeRepo(_ value: String) -> String {
        value.replacingOccurrences(of: "-", with: "_")
    }

    var prebuiltDependencyLabels: [String] {
        files.frameworks.compactMap { file in
            guard file.fileType == "wrapper.xcframework", let path = file.path, !path.isEmpty else { return nil }
            let name = Path(path).lastComponentWithoutExtension
            return "//Prebuilt:\(name)"
        }
    }

    var pathsForRoadmapTree: [String] {
        let allFiles = files.sources + files.headers + files.resources + files.others
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

private extension XCode.Project {
    struct RoadmapLocalPackage {
        let packagePath: Path
        let repoName: String
        let products: [String]
    }

    var roadmapLocalPackages: [RoadmapLocalPackage] {
        let usedLocalProducts = Set<String>(
            targets.flatMap { target -> [String] in
                target.dependencies.packageProducts.compactMap { product in
                    guard product.package == nil else { return nil }
                    return product.productName
                }
            }
        )

        let explicit = packages.local.compactMap { package -> RoadmapLocalPackage? in
            let packagePath = Path(workspacePath) + package.relativePath
            let manifest = packagePath + "Package.swift"
            guard let content = try? String(contentsOfFile: manifest.string) else { return nil }
            let localPackage = RoadmapLocalPackage(
                packagePath: packagePath,
                repoName: "swiftpkg_" + package.relativePath.packageRepoBasename,
                products: content.swiftPackageProductNames
            )
            guard !usedLocalProducts.isDisjoint(with: localPackage.products) else { return nil }
            return localPackage
        }

        if !explicit.isEmpty {
            return explicit
        }

        let workspace = Path(workspacePath)
        let children = (try? workspace.children()) ?? []
        return children
            .filter(\.isDirectory)
            .filter { ($0 + "Package.swift").exists }
            .compactMap { directory -> RoadmapLocalPackage? in
                let manifest = directory + "Package.swift"
                guard let content = try? String(contentsOfFile: manifest.string) else { return nil }
                let localPackage = RoadmapLocalPackage(
                    packagePath: directory,
                    repoName: "swiftpkg_" + directory.lastComponent.lowercased().replacingOccurrences(of: "-", with: "_"),
                    products: content.swiftPackageProductNames
                )
                guard !usedLocalProducts.isDisjoint(with: localPackage.products) else { return nil }
                return localPackage
            }
    }

    var localPackageRepoByProduct: [String: String] {
        var result: [String: String] = [:]

        for package in roadmapLocalPackages {
            for product in package.products {
                result[product] = package.repoName
            }
        }

        return result
    }

    var prebuiltXcframeworks: [XCode.File] {
        let all = targets.flatMap { target in
            target.files.frameworks.filter { $0.fileType == "wrapper.xcframework" }
        }

        var seen = Set<String>()
        return all.filter { file in
            guard let path = file.path else { return false }
            return seen.insert(path).inserted
        }
    }
}

private extension XCode.File {
    var roadmapRelativePath: String? {
        if let path, !path.isEmpty {
            return path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }
        return nil
    }
}

private extension Path {
    var isSelfReferentialSymlink: Bool {
        guard isSymlink else { return false }
        guard let destination = try? symlinkDestination().absolute() else { return false }
        return destination == absolute()
    }
}

private extension String {
    var swiftPackageProductNames: [String] {
        let pattern = #"\.library\s*\(\s*name:\s*"([^"]+)""#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(startIndex..., in: self)
        return regex.matches(in: self, range: range).compactMap { match in
            guard let capture = Range(match.range(at: 1), in: self) else { return nil }
            return String(self[capture])
        }
    }

    var packageRepoBasename: String {
        Path(self).lastComponent.lowercased().replacingOccurrences(of: "-", with: "_")
    }

    func wrappedValue(prefix: String) -> String? {
        guard hasPrefix(prefix), hasSuffix(")") else { return nil }
        return String(dropFirst(prefix.count).dropLast())
    }
}
