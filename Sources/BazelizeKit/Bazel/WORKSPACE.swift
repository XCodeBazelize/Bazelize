//
//  WORKSPACE.swift
//  
//
//  Created by Yume on 2022/4/27.
//

import Foundation
import PathKit

struct Workspace {
    private let code: String
    
    public init(_ build: (inout Builder) -> Void) {
        var builder = Builder()
        build(&builder)
        self.code = builder.build()
    }
    
    public init() {
        var builder = Builder()
        builder.default()
        self.code = builder.build()
    }

    // WORKSPACE
    public func generate(_ path: Path) throws {
        let workspace = path + "WORKSPACE"
        print("Create \(workspace.string)")
//        try _workspace.delete()
        try workspace.write(code)
    }
    
    public struct Builder {
        private var codes: [String] = []
        
        private var _code: String {
            get { "" }
            set { codes.append(newValue) }
        }
        
        mutating
        public func `default`() {
            self.http_archive()
            self.rulesApple(repo: .v1_0_1)
            self.rulesPod(repo: .v4_1_0_412495)
            self.rulesSPM(repo: .v0_11_0)
            self.rulesHammer(repo: .v3_4_3_3)
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
                sha256 = "\(repo.sha256)",
                url = "https://github.com/bazelbuild/rules_apple/releases/download/\(repo.rawValue)/rules_apple.\(repo.rawValue).tar.gz",
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
            http_archive(
                name = "cgrindel_rules_spm",
                # sha256 = "\(repo.sha256)",
                strip_prefix = "rules_spm-\(repo.rawValue)",
                urls = [
                    "http://github.com/cgrindel/rules_spm/archive/v\(repo.rawValue).tar.gz",
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
        public func rulesHammer(repo: Repo.XCHammer) {
            _code = """
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
        
        internal func build() -> String {
            return codes.joined(separator: "\n")
        }
    }
}
