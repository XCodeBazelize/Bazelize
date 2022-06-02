//
//  WORKSPACE.swift
//  
//
//  Created by Yume on 2022/4/27.
//

import Foundation
import PathKit

enum Workspace {
    static var code: String {
        return _workspace
    }
    
    // WORKSPACE
    static func generate(_ path: Path, other codes: String...) throws {
        let workspace = path + "WORKSPACE"
        print("Create \(workspace.string)")
//        try _workspace.delete()
        let all = [code] + codes
        try workspace.write(all.joined(separator: "\n"))
    }
}

private let _workspace = """
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "build_bazel_rules_apple",
    sha256 = "4161b2283f80f33b93579627c3bd846169b2d58848b0ffb29b5d4db35263156a",
    url = "https://github.com/bazelbuild/rules_apple/releases/download/0.34.0/rules_apple.0.34.0.tar.gz",
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

# rules_pods
http_archive(
    name = "rules_pods",
    urls = ["https://github.com/pinterest/PodToBUILD/releases/download/4.0.0-5787125/PodToBUILD.zip"],
    sha256 = "d697642a6ca9d4d0441a5a6132e9f2bf70e8e9ee0080c3c780fe57e698e79d82",
)

load("@rules_pods//BazelExtensions:workspace.bzl", "new_pod_repository")

# xchammer
http_archive(
    name = "xchammer",
    urls = [ "https://github.com/pinterest/xchammer/releases/download/v3.4.3.3/xchammer.zip" ],
)

# spm
http_archive(
    name = "cgrindel_rules_spm",
    sha256 = "ba4310ba33cd1864a95e41d1ceceaa057e56ebbe311f74105774d526d68e2a0d",
    strip_prefix = "rules_spm-0.10.0",
    urls = [
        "http://github.com/cgrindel/rules_spm/archive/v0.10.0.tar.gz",
    ],
)

load(
    "@cgrindel_rules_spm//spm:deps.bzl",
    "spm_rules_dependencies",
)

spm_rules_dependencies()
"""
