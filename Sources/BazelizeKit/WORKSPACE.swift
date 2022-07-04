//
//  WORKSPACE.swift
//  
//
//  Created by Yume on 2022/4/27.
//

import Foundation
import PathKit

enum Rule {
    enum Apple: String {
        case v1_0_1 = "1.0.1"
        
        var sha256: String {
            return "36072d4f3614d309d6a703da0dfe48684ec4c65a89611aeb9590b45af7a3e592"
        }
    }
    
    enum Pod: String {
        case v4_1_0_412495 = "4.1.0-412495"
        var sha256: String {
            return "d697642a6ca9d4d0441a5a6132e9f2bf70e8e9ee0080c3c780fe57e698e79d82"
        }
    }
    
    enum SPM: String {
        case v0_11_0 = "0.11.0"
        var sha256: String {
            return "03718eb865a100ba4449ebcbca6d97bf6ea78fa17346ce6d55532312e8bf9aa8"
        }
    }
}

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
            self.rulesApple(rule: .v1_0_1)
            self.rulesPod(rule: .v4_1_0_412495)
            self.rulesSPM(rule: .v0_11_0)
        }
        
        mutating
        public func http_archive() {
            _code = """
            load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
            """
        }
        
        mutating
        public func rulesApple(rule: Rule.Apple) {
            _code = """
            # rules_apple
            http_archive(
                name = "build_bazel_rules_apple",
                sha256 = "\(rule.sha256)",
                url = "https://github.com/bazelbuild/rules_apple/releases/download/\(rule.rawValue)/rules_apple.\(rule.rawValue).tar.gz",
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
        public func rulesPod(rule: Rule.Pod) {
            _code = """
            # rules_pods
            http_archive(
                name = "rules_pods",
                urls = ["https://github.com/pinterest/PodToBUILD/releases/download/\(rule.rawValue)/PodToBUILD.zip"],
                sha256 = "\(rule.sha256)",
            )

            load("@rules_pods//BazelExtensions:workspace.bzl", "new_pod_repository")
            """
        }
        
        mutating
        public func rulesSPM(rule: Rule.SPM) {
            _code = """
            http_archive(
                name = "cgrindel_rules_spm",
                sha256 = "\(rule.sha256)",
                strip_prefix = "rules_spm-\(rule.rawValue)",
                urls = [
                    "http://github.com/cgrindel/rules_spm/archive/v\(rule.rawValue).tar.gz",
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
        public func custom(code: String) {
            _code = code
        }
        
        internal func build() -> String {
            return codes.joined(separator: "\n")
        }
    }
}

private let _workspace = """
# xchammer
http_archive(
    name = "xchammer",
    urls = [ "https://github.com/pinterest/xchammer/releases/download/v3.4.3.3/xchammer.zip" ],
)
"""
