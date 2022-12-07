//
//  Logger.swift
//
//
//  Created by Yume on 2022/10/10.
//

import Foundation
import os
import OSLog

public enum Log {
    private static let domain = "com.xcode.bazelize"

    public static let codeGenerate = Logger(subsystem: domain, category: "code generate")
    public static let pluginLoader = Logger(subsystem: domain, category: "plugin loader")
    public static let dump = Logger(subsystem: domain, category: "dump")
}
