//
//  PluginOther.swift
//
//
//  Created by Yume on 2023/1/31.
//

import Foundation
import PathKit
import PluginInterface
import XCode
import XcodeProj

// MARK: - PluginSPM2

final class PluginSPM2: PluginBuiltin {
    let remotes: [XCodeRemoteSPM]
    let locals: [XCodeLocalSPM]

    override init(_ kit: Kit) {
        remotes = kit.project.remoteSPM
        locals = kit.project.localSPM
        super.init(kit)
    }

    private func transformRemote(_ product: XCSwiftPackageProductDependency) -> String? {
        guard let url = product.package?.repositoryURL else { return nil }
        /// https://github.com/apple/swift-nio.git
        let path = Path(url)

        /// swift-nio
        let repo = path.lastComponentWithoutExtension.lowercased()

        /// NIO
        let product = product.productName

        /// @swiftpkg_swift_nio//:Sources_NIO
        return """
        @swiftpkg_\(repo)//:Sources_\(product)
        """.replacingOccurrences(of: "-", with: "_")
    }

    private func transformLocal(_ product: XCSwiftPackageProductDependency) -> [String]? {
        let product = product.productName

        let local = locals.first { spm in
            spm.products.keys.contains(product)
        }

        guard let local = local else { return nil }
        guard let targets = local.products[product] else { return nil }
        let path = Path(local.path).lastComponent.lowercased()

        return targets.map { target in
            // TODO: ?
            ///
            /// change `//Local1/Sources/LocalTarget1`
            /// to     `@swiftpkg_local1//:Sources_LocalTarget1`
            ///
            /// @swiftpkg_\(local.path.lowercased())//:Sources_\(target)
            /// # //\(local.path)/Sources/\(target)
            """
            @swiftpkg_\(path)//:Sources_\(target)
            """
        }
    }

    override var target: [String : [String]]? {
        let targets = kit.project.targets.compactMap { $0 as? Target }

        let pair = targets.map { target in
            let deps = target.native.packageProductDependencies

            let remote = deps.compactMap(transformRemote)
            let local = deps.compactMap(transformLocal).flatMap { $0 }
            let all: [String] = Set(remote + local).sorted()
            return (target.name, all)
        }

        return pair.toDictionary()
    }

    override var workspace: String? {
        """
        http_archive(
            name = "cgrindel_swift_bazel",
            sha256 = "fd77181e45fbb9ab6ddedf59f3f2d4cf0c173919a6de8d4a398d99fd965d5ce5",
            strip_prefix = "swift_bazel-0.2.0",
            urls = [
                "http://github.com/cgrindel/swift_bazel/archive/v0.2.0.tar.gz",
            ],
        )

        load("@cgrindel_swift_bazel//:deps.bzl", "swift_bazel_dependencies")

        swift_bazel_dependencies()

        load("@cgrindel_bazel_starlib//:deps.bzl", "bazel_starlib_dependencies")

        bazel_starlib_dependencies()

        # MARK: - Gazelle

        # gazelle:repo bazel_gazelle

        load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")
        load("@cgrindel_swift_bazel//:go_deps.bzl", "swift_bazel_go_dependencies")
        load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")

        # Declare Go dependencies before calling go_rules_dependencies.
        swift_bazel_go_dependencies()

        go_rules_dependencies()

        go_register_toolchains(version = "1.19.1")

        gazelle_dependencies()

        load("//:swift_deps.bzl", "swift_dependencies")

        # gazelle:repository_macro swift_deps.bzl%swift_dependencies
        swift_dependencies()
        """
    }

    override var build: String? {
        """
        load("@bazel_gazelle//:def.bzl", "gazelle", "gazelle_binary")
        load("@cgrindel_swift_bazel//swiftpkg:defs.bzl", "swift_update_packages")

        # Ignore the `.build` folder that is created by running Swift package manager
        # commands. The Swift Gazelle plugin executes some Swift package manager
        # commands to resolve external dependencies. This results in a `.build` file
        # being created.
        # NOTE: Swift package manager is not used to build any of the external packages.
        # The `.build` directory should be ignored. Be sure to configure your source
        # control to ignore it (i.e., add it to your `.gitignore`).
        # gazelle:exclude .build

        # This declaration builds a Gazelle binary that incorporates all of the Gazelle
        # plugins for the languages that you use in your workspace. In this example, we
        # are using the Gazelle plugin for Starlark from bazel_skylib and the Gazelle
        # plugin for Swift from cgrindel_swift_bazel.
        gazelle_binary(
            name = "gazelle_bin",
            languages = [
                "@bazel_skylib//gazelle/bzl",
                "@cgrindel_swift_bazel//gazelle",
            ],
        )

        # This macro defines two targets: `swift_update_pkgs` and
        # `swift_update_pkgs_to_latest`.
        #
        # The `swift_update_pkgs` target should be run whenever the list of external
        # dependencies is updated in the `Package.swift`. Running this target will
        # populate the `swift_deps.bzl` with `swift_package` declarations for all of
        # the direct and transitive Swift packages that your project uses.
        #
        # The `swift_update_pkgs_to_latest` target should be run when you want to
        # update your Swift dependencies to their latest eligible version.
        swift_update_packages(
            name = "swift_update_pkgs",
            gazelle = ":gazelle_bin",
        )

        # This target updates the Bazel build files for your project. Run this target
        # whenever you add or remove source files from your project.
        gazelle(
            name = "update_build_files",
            gazelle = ":gazelle_bin",
        )

        load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

        bzl_library(
            name = "swift_deps",
            srcs = ["swift_deps.bzl"],
            visibility = ["//visibility:public"],
            deps = ["@cgrindel_swift_bazel//swiftpkg:defs"],
        )
        """
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
                ])
            """)
    }

    private var dep: PluginBuiltin.Custom {
        .init(
            path: "swift_deps.bzl",
            content: """
            # Contents of swift_deps.bzl
            def swift_dependencies():
                pass
            """)
    }

    override var custom: [PluginBuiltin.Custom]? {
        [package, dep]
    }

    override var tip: String? {
        if remotes.isEmpty, locals.isEmpty { return nil }
        return """
        # swift_bazel
        Make sure to update `swift_deps.bzl`.
        Please run `bazel run //:swift_update_pkgs` after bazelize.
        """
    }
}

// MARK: - PluginApple

final class PluginApple: PluginBuiltin {
    let repo: Repo.Apple = .v2_0_0

    override var module: String? {
        """
        bazel_dep(name = "rules_apple", version = "2.0.0", repo_name = "build_bazel_rules_apple")
        """
    }

    override var workspace: String? {
        let version = repo.version
        return """
        # rules_apple
        http_archive(
            name = "build_bazel_rules_apple",
            sha256 = "\(repo.sha256)",
            url = "https://github.com/bazelbuild/rules_apple/releases/download/\(version)/rules_apple.\(version).tar.gz",
        )

        load(
            "@build_bazel_rules_apple//apple:repositories.bzl",
            "apple_rules_dependencies",
        )

        apple_rules_dependencies()

        load(
            "@build_bazel_apple_support//lib:repositories.bzl",
            "apple_support_dependencies",
        )

        apple_support_dependencies()
        """
    }
}

// MARK: - PluginSwift

final class PluginSwift: PluginBuiltin {
    let repo: Repo.Swift = .v1_5_0

    override var module: String? {
        """
        bazel_dep(name = "rules_swift", version = "\(repo.version)", repo_name = "build_bazel_rules_swift")
        """
    }

    override var workspace: String? {
        """
        # rules_swift
        http_archive(
            name = "build_bazel_rules_swift",
            sha256 = "\(repo.sha256)",
            url = "https://github.com/bazelbuild/rules_swift/releases/download/\(repo.rawValue)/rules_swift.\(
                repo
                    .rawValue).tar.gz",
        )

        load(
            "@build_bazel_rules_swift//swift:repositories.bzl",
            "swift_rules_dependencies",
        )

        swift_rules_dependencies()

        load(
            "@build_bazel_rules_swift//swift:extras.bzl",
            "swift_rules_extra_dependencies",
        )

        swift_rules_extra_dependencies()
        """
    }
}

// MARK: - PluginXCodeProj

final class PluginXCodeProj: PluginBuiltin {
    let repo: Repo.XCodeProj = .v0_11_0
    override var module: String? {
        """
        bazel_dep(name = "rules_xcodeproj", version = "0.12.3")
        """
    }

    override var workspace: String? {
        """
        # rules_xcodeproj
        http_archive(
            name = "com_github_buildbuddy_io_rules_xcodeproj",
            sha256 = "\(repo.sha256)",
            url = "https://github.com/buildbuddy-io/rules_xcodeproj/releases/download/\(repo.rawValue)/release.tar.gz",
        )

        load(
            "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:repositories.bzl",
            "xcodeproj_rules_dependencies",
        )

        xcodeproj_rules_dependencies()
        """
    }
}

// MARK: - PluginPlistFragment

final class PluginPlistFragment: PluginBuiltin {
    override var workspace: String? {
        """
        load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
        git_repository(
            name = "Plist",
            commit = "259ca0a5d77833728c18fa6365285559ce8cc0bf",
            remote = "https://github.com/imWildCat/MinimalBazelFrameworkDemo",
        )
        """
    }
}
