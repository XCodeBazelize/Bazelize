//
//  RulesPlist.swift
//
//
//  Created by Yume on 2022/8/26.
//

import Foundation

enum RulesPlist: String, LoadableRule {
    static let target = "@Plist//build-system/ios-utils:plist_fragment.bzl"

    case plist_fragment
}
