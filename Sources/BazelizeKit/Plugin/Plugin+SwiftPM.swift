//
//  PluginSPM2.swift
//
//
//  Created by Yume on 2023/1/31.
//

import Foundation
import PathKit
import XCode
import XcodeProj

// MARK: - PluginSPM

/// http://github.com/cgrindel/rules_swift_package_manager
final class PluginSwiftPM: PluginBuiltin {
    private let repo: Repo.SPM = .v1_13_0
    let remotes: [XCodeRemoteSPM]
    let locals: [XCodeLocalSPM]
    private var packages: [String] = []
    func loadPackageNames(projPath: Path) async throws {
        let packageSwift = package
        let path = Path(packageSwift.path)
        try path.write(packageSwift.content)
        packages = try await SPMParser
            .allPackageNames(path: projPath.parent().string)
    }

    override init(_ kit: Kit) {
        remotes = kit.project.remoteSPM
        locals = kit.project.localSPM
        super.init(kit)
    }

    override func module(_ builder: CodeBuilder) {
        builder.bazelDep(name: "rules_swift_package_manager", version: repo.rawValue)
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

    private func transformRemote(_ product: XCSwiftPackageProductDependency) -> String? {
        guard let url = product.package?.repositoryURL else { return nil }
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

    private func transformLocal(_ product: XCSwiftPackageProductDependency) -> String? {
        let product = product.productName

        let local = locals.first { spm in
            spm.products.keys.contains(product)
        }

        guard let local = local else { return nil }
        let path = Path(local.path).lastComponent.lowercased()

        return """
        @swiftpkg_\(path)//:\(product)
        """
    }

    override var target: [String : [String]]? {
        let targets = kit.project.targets

        return targets.map { target -> (String, [String]) in
            let deps = target.native.packageProductDependencies ?? []

            let remote = deps.compactMap(transformRemote)
            let local = deps.compactMap(transformLocal)
            let all: [String] = Set(remote + local).sorted()
            return (target.name, all)
        }.toDictionary()
    }

    private var package: PluginBuiltin.Custom {
        let spms = remotes.map(\.package) +
            locals.map(\.package)
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

    override var tip: String? {
        if remotes.isEmpty, locals.isEmpty { return nil }
        return """
        # rules_swift_package_manager
        After bazelize, run `swift package update` and `bazel mod tidy`.
        """
    }

    private var packageRepositories: [String] {
        let remoteRepos = remotes.map(\.url).map(Self.repositoryName(url:))
        let localRepos = locals.map(\.path).map(Self.repositoryName(path:))
        return Set(remoteRepos + localRepos).sorted()
    }

    private static func repositoryName(url: String) -> String {
        return repositoryName(module: Path(url).lastComponentWithoutExtension)
    }

    private static func repositoryName(path: String) -> String {
        return repositoryName(module: Path(path).lastComponent)
    }
    
    private static func repositoryName(module: String) -> String {
        return "swiftpkg_\(sanitize(module.lowercased()))"
    }

    private static func sanitize(_ value: String) -> String {
        value.replacingOccurrences(of: "-", with: "_")
    }
}
