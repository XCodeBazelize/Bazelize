//
//  Plugin.swift
//  
//
//  Created by Yume on 2022/7/16.
//

import Foundation
import PathKit

public protocol Plugin: AnyObject {
    /// plugin name
    var name: String { get }
    
    static func load(_ proj: XCodeProject) async throws -> Self?
    
    subscript(target: String) -> PluginTarget? { get }

    /// # rules_pods
    /// http_archive(
    ///     name = "rules_pods",
    ///     urls = ["https://github.com/pinterest/PodToBUILD/releases/download/4.1.0-412495/PodToBUILD.zip"],
    ///     # sha256 = "",
    /// )
    ///
    /// load("@rules_pods//BazelExtensions:workspace.bzl", "new_pod_repository")
    func workspace() -> String

    /// {WORKSPACE}/Pods.WORKSPACE
    func generateFile(_ workspace: Path) throws

    /// bazel run @rules_pods//:update_pods -- --src_root `PWD`
    func tip()
}

public protocol PluginTarget {
    var deps: [String] { get }
    var framework: [String] { get }
}
