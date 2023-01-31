//
//  Module.swift
//
//
//  Created by Yume on 2023/1/30.
//

import Foundation
import PathKit

/// https://github.com/bazelbuild/bazel-central-registry
struct Module: BazelFile {
    let path: Path
    let code = """
    module(
        name = "example",
        version = "0.0.1",
    )

    bazel_dep(name = "bazel_skylib", version = "1.4.0")

    # bazel_dep(name = "gazelle", version = "0.28.0")
    # bazel_dep(name = "rules_go", version = "0.38.1")
    # bazel_dep(name = "bazel_skylib_gazelle_plugin", version = "1.4.0", repo_name = "bazel_gazelle")
    """

    init(_ root: Path) {
        path = root + "MODULE.bazel"
    }
}
