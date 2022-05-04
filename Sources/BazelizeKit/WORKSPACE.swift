//
//  File.swift
//  
//
//  Created by Yume on 2022/4/27.
//

import Foundation
import PathKit

enum Workspace {
    static var code: String {
        return workspace
    }
    
    // WORKSPACE
    static func generate(_ path: Path) throws {
        let _workspace = path + "WORKSPACE"
//        try _workspace.delete()
        try _workspace.write(workspace)
    }
}

private let workspace = """
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
"""
