//
//  Rules+XcodeProj.swift
//
//
//  https://github.com/MobileNativeFoundation/rules_xcodeproj
//

import Foundation
import Starlark

// MARK: - Rules.XcodeProj

extension Rules {
    public enum XcodeProj: String, LoadableRule {
        public var module: String {
            "@rules_xcodeproj//xcodeproj:defs.bzl"
        }

        case xcodeproj
    }
}

// MARK: - Rules.XcodeProj.Call

extension Rules.XcodeProj {
    public enum Call {
        /// Builds an `xcodeproj` target.
        public static func xcodeproj(
            name: String,
            project_name: String? = nil,
            tags: [String]? = nil,
            top_level_targets: [Starlark.Label])
            -> Starlark.Statement.Call
        {
            Rules.XcodeProj.xcodeproj.call {
                Attr.name(name)
                Attr.project_name(project_name)
                Attr.tags(tags)
                Attr.top_level_targets(top_level_targets)
            }
        }
    }
}
