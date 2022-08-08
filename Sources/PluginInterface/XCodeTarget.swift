//
//  XCodeTarget.swift
//
//
//  Created by Yume on 2022/7/29.
//

import Foundation

public protocol XCodeTarget {
    /// Target Name
    var name: String { get }

    /// Release/Debug/More ...
    var configs: [String] { get }

    var config: [String: XCodeBuildSetting] { get }

    /// `.h` & `.pch`
    /// headers in current Target(Bazel Package)
    var headers: [String] { get }

    /// `.hpp`
    /// headers in current Target(Bazel Package)
    var hpps: [String] { get }

    /// all build file
    var srcs: [String] { get }
    var srcs_c: [String] { get }
    var srcs_objc: [String] { get }
    var srcs_cpp: [String] { get }
    var srcs_objcpp: [String] { get }
    var srcs_swift: [String] { get }
    var srcs_metal: [String] { get }

    var resources: [String] { get }

    /// use for `frameworks`
    var importFrameworks: [String] { get }

    /// use for `frameworks`
    var frameworks: [String] { get }

    /// use for `xxx_library.deps`
    ///
    var frameworks_library: [String] { get }

    /// use for `sdk_frameworks`
    var sdkFrameworks: [String] { get }
}
