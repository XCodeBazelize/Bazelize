//
//  File.swift
//
//
//  Created by Yume on 2022/8/24.
//

import Foundation
import PluginInterface

private typealias InitFunction = @convention(c)
    () -> UnsafeMutableRawPointer

// MARK: - DynamicLoadError

enum DynamicLoadError: Error {
    case symbolNotFound(symbolName: String, path: String)
    case openFail(reason: String, path: String)
    case unknown(path: String)
}

// MARK: - PluginLoader

enum PluginLoader {
    static func load(at path: String, proj: XCodeProject) async throws -> Plugin? {
        let openRes = dlopen(path, RTLD_NOW|RTLD_LOCAL)
        if openRes != nil {
            defer {
                dlclose(openRes)
            }

            let symbolName = "createPlugin"
            let sym = dlsym(openRes, symbolName)

            if sym != nil {
                let f: InitFunction = unsafeBitCast(sym, to: InitFunction.self)
                let pluginPointer = f()
                let builder = Unmanaged<PluginInterface.PluginBuilder>.fromOpaque(pluginPointer).takeRetainedValue()

                return try await builder.build(proj)
            } else {
                throw DynamicLoadError.symbolNotFound(symbolName: symbolName, path: path)
            }
        } else {
            if let err = dlerror() {
                throw DynamicLoadError.openFail(reason: String(format: "%s", err), path: path)
            } else {
                throw DynamicLoadError.unknown(path: path)
            }
        }
    }
}

