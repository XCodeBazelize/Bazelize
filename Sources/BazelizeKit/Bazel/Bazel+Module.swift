//
//  Module.swift
//
//
//  Created by Yume on 2023/1/30.
//

import Foundation
import PathKit
import RuleBuilder

extension Bazel {
    /// https://github.com/bazelbuild/bazel-central-registry
    struct Module: BazelFile {
        let path: Path
        public let builder = CodeBuilder()
        
        init(_ root: Path) {
            path = root + "MODULE.bazel"
            
            setup()
        }
        
        var code: String {
            builder.build()
        }
        
        private func setup() {
            builder.add("module") {
                "name" => "example"
                "version" => "0.0.1"
            }
            builder.bazel_dep(name: "bazel_skylib", version: "1.9.0")
            builder.bazel_dep(name: "rules_cc", version: "0.2.17")
        }
    }
    
}
