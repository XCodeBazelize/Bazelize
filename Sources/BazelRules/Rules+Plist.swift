//
//  Rules+Plist.swift
//
//
//  Created by Yume on 2022/8/26.
//

import Foundation

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
