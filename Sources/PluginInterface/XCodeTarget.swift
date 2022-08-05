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
    /// `.c`
    var srcs_c: [String] { get }
    /// `.m`
    var srcs_objc: [String] { get }
    /// `.cpp`
    var srcs_cpp: [String] { get }
    /// `.mm`
    var srcs_objcpp: [String] { get }
    /// `.swift`
    var srcs_swift: [String] { get }
    /// `.metal`
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
