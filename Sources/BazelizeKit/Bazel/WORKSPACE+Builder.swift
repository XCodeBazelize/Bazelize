//
//  Workspace.swift
//
//
//  Created by Yume on 2022/7/25.
//

import Foundation

extension Workspace {
    public struct Builder {
        // MARK: Public

        mutating
        public func `default`() {
            http_archive()
            rulesApple(repo: .v2_0_0)
            rulesSwift(repo: .v1_5_0)
            rulesPod(repo: .v4_1_0_412495)
//            rulesSPM(repo: .v0_11_2)
            rulesSPM2()
//            rulesHammer(repo: .v3_4_3_3)
            rulesXCodeProj(repo: .v0_11_0)
        }

        mutating
        public func http_archive() {
            _code = """
            load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
            """
        }

        mutating
        public func rulesApple(repo: Repo.Apple) {
            let version = repo.version
            _code = """
            # rules_apple
            http_archive(
                name = "build_bazel_rules_apple",
                # sha256 = "\(repo.sha256)",
                url = "https://github.com/bazelbuild/rules_apple/releases/download/\(version)/rules_apple.\(version).tar.gz",
            )

            load(
                "@build_bazel_rules_apple//apple:repositories.bzl",
                "apple_rules_dependencies",
            )

            apple_rules_dependencies()

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

            load(
                "@build_bazel_apple_support//lib:repositories.bzl",
                "apple_support_dependencies",
            )

            apple_support_dependencies()
            """
        }

        mutating
        public func rulesPod(repo: Repo.Pod) {
            _code = """
            # rules_pods
            http_archive(
                name = "rules_pods",
                urls = ["https://github.com/pinterest/PodToBUILD/releases/download/\(repo.rawValue)/PodToBUILD.zip"],
                # sha256 = "\(repo.sha256)",
            )

            load("@rules_pods//BazelExtensions:workspace.bzl", "new_pod_repository")
            """
        }

        mutating
        public func rulesSPM(repo: Repo.SPM) {
            _code = """
            # rules_spm
            http_archive(
                name = "cgrindel_rules_spm",
                # sha256 = "\(repo.sha256)",
                strip_prefix = "rules_spm-\(repo.version)",
                urls = [
                    "http://github.com/cgrindel/rules_spm/archive/\(repo.rawValue).tar.gz",
                ],
            )

            load(
                "@cgrindel_rules_spm//spm:deps.bzl",
                "spm_rules_dependencies",
            )

            spm_rules_dependencies()
            """
        }

        mutating
        public func rulesSPM2() {
            _code = """
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

            # MARK: - Swift Toolchain

            http_archive(
                name = "build_bazel_rules_swift",
                # Populate with your preferred release
                # https://github.com/bazelbuild/rules_swift/releases
            )

            load(
                "@build_bazel_rules_swift//swift:repositories.bzl",
                "swift_rules_dependencies",
            )
            load("//:swift_deps.bzl", "swift_dependencies")

            # gazelle:repository_macro swift_deps.bzl%swift_dependencies
            swift_dependencies()

            swift_rules_dependencies()

            load(
                "@build_bazel_rules_swift//swift:extras.bzl",
                "swift_rules_extra_dependencies",
            )

            swift_rules_extra_dependencies()
            """
        }

        mutating
        public func rulesHammer(repo: Repo.Hammer) {
            _code = """
            # rules_hammer
            http_archive(
                name = "xchammer",
                urls = [ "https://github.com/pinterest/xchammer/releases/download/\(repo.rawValue)/xchammer.zip" ],
            )
            """
        }

        mutating
        public func rulesXCodeProj(repo: Repo.XCodeProj) {
            _code = """
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

        mutating
        public func rulesPlistFragment() {
            _code = """
            load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
            git_repository(
                name = "Plist",
                commit = "259ca0a5d77833728c18fa6365285559ce8cc0bf",
                remote = "https://github.com/imWildCat/MinimalBazelFrameworkDemo",
            )
            """
        }

        mutating
        public func rulesSwift(repo: Repo.Swift) {
            _code = """
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

        mutating
        public func custom(code: String) {
            _code = code
        }

        // MARK: Internal

        internal func build() -> String {
            codes.joined(separator: "\n\n")
        }

        // MARK: Private

        private var codes: [String] = []


        private var _code: String {
            get { "" }
            set { codes.append(newValue) }
        }
    }
}
