//
//  Plugin.swift
//
//
//  Created by Yume on 2022/7/16.
//

import Foundation
import PathKit
import XCode

// MARK: - PluginBuilder

open class PluginBuilder {
    public init() { }

    open func build(_: Project) async throws -> Plugin? {
        fatalError("You have to override this method.")
    }
}

// MARK: - Plugin

public protocol Plugin: AnyObject {
    var name: String { get }
    var description: String { get }
    var version: String { get }
    var url: String { get }

    static func load(_ proj: Project) async throws -> Self?

    subscript(_: String) -> PluginTarget? { get }

    func workspace() -> String
    func generateFile(_ workspace: Path) throws
    func tip()
}

// MARK: - PluginTarget

public protocol PluginTarget {
    var deps: [String] { get }
    var framework: [String] { get }
}
