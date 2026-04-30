//
//  PluginSPM2.swift
//
//
//  Created by Yume on 2023/1/31.
//

import Foundation
import PathKit

// MARK: - PluginSPM

/// http://github.com/cgrindel/rules_swift_package_manager
final class PluginSwiftPM: PluginBuiltin {
    private let repo: Repo.SwiftPM = .v1_15_0
    let remotes: [RemotePackage]
    let locals: [LocalPackage]
    private var packages: [String] = []
    func loadPackageNames(projPath: Path) async throws {
        let packageSwift = package
        let workspace = projPath.parent()
        let path = workspace + packageSwift.path
        let hadExistingManifest = path.exists
        let originalContent = hadExistingManifest ? (try? path.read()) : nil

        try path.write(packageSwift.content)
        defer {
            if hadExistingManifest {
                if let originalContent {
                    try? path.write(originalContent)
                }
            } else {
                try? path.delete()
            }
        }

        packages = packageRepositories
    }

    override init(_ kit: Kit) {
        remotes = kit.project.packages.remote
        locals = kit.project.packages.local
        super.init(kit)
    }

    override func module(_ builder: CodeBuilder) {
        builder.bazel_dep(
            name: "rules_swift_package_manager",
            version: repo.rawValue)
        builder.custom("""
        swift_deps = use_extension(
            "@rules_swift_package_manager//:extensions.bzl",
            "swift_deps",
        )
        swift_deps.from_package(
            declare_swift_deps_info = True,
            resolved = "//:Package.resolved",
            swift = "//:Package.swift",
        )
        """)

        let names = packages.map {
            "\(Self.repositoryName(module: $0))".quoted
        }.joined(separator: ",")
        builder.custom("""
        use_repo(
            swift_deps,
        \(names)
        )
        """)
    }

    private func transformRemote(_ product: PackageProductDependency) -> String? {
        guard let url = product.package else { return nil }
        /// https://github.com/apple/swift-nio.git
        let path = Path(url)

        /// swift-nio
        let repo = path.lastComponentWithoutExtension.lowercased()

        /// NIO
        let product = product.productName

        /// @swiftpkg_swift_nio//:NIO
        return """
        @\(Self.repositoryName(module: repo))//:\(product)
        """.replacingOccurrences(of: "-", with: "_")
    }

    private func transformLocal(_ product: PackageProductDependency) -> String? {
        let product = product.productName

        let path: String
        if let packagePath = kit.project.localPackagePathByProduct[product] {
            path = Path(packagePath).lastComponent.lowercased()
        } else if let packagePath = kit.project.localPackageRepoByProduct[product] {
            path = packagePath.replacingOccurrences(of: "swiftpkg_", with: "")
        } else {
            return nil
        }

        return """
        @swiftpkg_\(path)//:\(product)
        """
    }

    override var target: [String : [String]]? {
        let targets = kit.project.targets

        return targets.map { target -> (String, [String]) in
            let deps = target.dependencies.packageProducts

            let remote = deps.compactMap(transformRemote)
            let local = deps.compactMap(transformLocal)
            let all: [String] = Set(remote + local).sorted()
            return (target.name, all)
        }.toDictionary()
    }

    private var package: PluginBuiltin.Custom {
        let spms = remotes.compactMap { remote -> String? in
            guard let url = remote.repositoryURL else { return nil }
            if let version = remote.version {
                switch version {
                case .upToNextMajorVersion(let version):
                    return #"        .package(url: "\#(url)", from: "\#(version)"),"#
                case .upToNextMinorVersion(let version):
                    return #"        .package(url: "\#(url)", .upToNextMinor(from: "\#(version)")),"#
                case .exact(let version):
                    return #"        .package(url: "\#(url)", exact: "\#(version)"),"#
                case .branch(let branch):
                    return #"        .package(url: "\#(url)", branch: "\#(branch)"),"#
                case .revision(let revision):
                    return #"        .package(url: "\#(url)", revision: "\#(revision)"),"#
                case .range(let from, let to):
                    return #"        .package(url: "\#(url)", "\#(from)"..."\#(to)"),"#
                }
            }
            return #"        .package(url: "\#(url)", from: "0.0.1"),"#
        } +
            locals.map { local in
                #"        .package(path: "\#(localPackagePath(local))"),"#
            }
        let deps = spms.joined(separator: "\n").indent(2)
        return .init(
            path: "Package.swift",
            content: """
            // swift-tools-version: 5.7
            import PackageDescription

            let package = Package(
                name: "MySwiftPackage",
                dependencies: [
            \(deps)
                ]
            )
            """)
    }

    override var custom: [PluginBuiltin.Custom]? {
        [package]
    }

    override var tip: String? {
        if remotes.isEmpty, locals.isEmpty { return nil }
        return """
        # rules_swift_package_manager
        After bazelize, run `swift package update` and `bazel mod tidy`.
        """
    }

    private var packageRepositories: [String] {
        let remoteRepos = remotes.compactMap(\.repositoryURL).map(Self.repositoryName(url:))
        let localRepos = locals.map(\.relativePath).map(Self.repositoryName(path:))
        return Set(remoteRepos + localRepos).sorted()
    }

    private func localPackagePath(_ local: LocalPackage) -> String {
        let source = (kit.project.workspaceRoot + local.relativePath).absolute()
        let base = kit.outputRoot.absolute()
        return Self.relativePath(from: base.string, to: source.string)
    }

    private static func repositoryName(url: String) -> String {
        repositoryName(module: Path(url).lastComponentWithoutExtension)
    }

    private static func repositoryName(path: String) -> String {
        repositoryName(module: Path(path).lastComponent)
    }

    private static func repositoryName(module: String) -> String {
        "swiftpkg_\(sanitize(module.lowercased()))"
    }

    private static func sanitize(_ value: String) -> String {
        value.replacingOccurrences(of: "-", with: "_")
    }

    private static func relativePath(from base: String, to target: String) -> String {
        let baseURL = URL(fileURLWithPath: base, isDirectory: true).standardized
        let targetURL = URL(fileURLWithPath: target, isDirectory: true).standardized

        let baseComponents = baseURL.pathComponents
        let targetComponents = targetURL.pathComponents

        var commonCount = 0
        while
            commonCount < min(baseComponents.count, targetComponents.count),
            baseComponents[commonCount] == targetComponents[commonCount]
        {
            commonCount += 1
        }

        let upward = Array(repeating: "..", count: baseComponents.count - commonCount)
        let downward = Array(targetComponents.dropFirst(commonCount))
        return (upward + downward).joined(separator: "/")
    }
}
