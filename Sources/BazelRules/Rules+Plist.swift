//
//  Rules+Plist.swift
//
//
//  Created by Yume on 2022/8/26.
//

import Foundation
import RuleBuilder

/// Local plist fragment helper rules.
extension Rules {
    public enum Plist: String, LoadableRule {
        public var module: String {
            "@Plist//build-system/ios-utils:plist_fragment.bzl"
        }

        case plist_fragment
    }
}

@available(*, deprecated, renamed: "Rules.Plist")
public typealias RulesPlist = Rules.Plist

public extension Rules.Plist {
    enum Call {
        public static func plist_fragment(
            name: String,
            ext: String,
            template: Starlark.Value,
            visibility: Starlark.Statement.Argument.Visibility? = nil
        ) -> Starlark.Statement.Call {
            Rules.Plist.plist_fragment.call {
                "name" => name
                "extension" => ext
                "template" => template
                if let visibility { visibility }
            }
        }
    }
}
