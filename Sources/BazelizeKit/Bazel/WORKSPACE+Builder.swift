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

//        mutating
//        public func `default`() {
//            http_archive()
//            rulesApple(repo: .v2_0_0)
//            rulesSwift(repo: .v1_5_1)
//            rulesPod(repo: .v4_1_0_412495)
//            rulesSPM(repo: .v0_11_2)
//            rulesSPM2()
//            rulesXCodeProj(repo: .v0_11_0)
//            rulesHammer(repo: .v3_4_3_3)
//        }

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
