//
//  Env.swift
//
//
//  Created by Yume on 2022/4/27.
//

import Foundation

public enum Env {
    /// COCOAPOD
    public static var pod: String {
        ProcessInfo.processInfo.environment["COCOAPOD"] ?? "/usr/local/bin/pod"
    }
}
