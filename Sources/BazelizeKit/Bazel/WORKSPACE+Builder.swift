//
//  File.swift
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
            rulesApple(repo: .v1_1_0)
            rulesPod(repo: .v4_1_0_412495)
//            self.rulesSPM(repo: .v0_11_0)
//            self.rulesHammer(repo: .v3_4_3_3)
        }

        mutating
        public func http_archive() {
            _code = """
            load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
            """
        }

        mutating
        public func rulesApple(repo: Repo.Apple) {
            _code = """
            # rules_apple
            http_archive(
                name = "build_bazel_rules_apple",
                # sha256 = "\(repo.sha256)",
                url = "https://github.com/bazelbuild/rules_apple/releases/download/\(repo.version)/rules_apple.\(repo
                .version).tar.gz",
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
        public func custom(code: String) {
            _code = code
        }

        // MARK: Internal

        internal func build() -> String {
            codes.withNewLine
        }

        // MARK: Private

        private var codes: [String] = []


        private var _code: String {
            get { "" }
            set { codes.append(newValue) }
        }
    }
}
