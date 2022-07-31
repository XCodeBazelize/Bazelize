//
//  Pod.swift
//  
//
//  Created by Yume on 2022/4/26.
//

import Foundation
import Util
import PathKit
import PluginInterface

public final class Pod {
    public let name = "Cocoapod"
    
    let podfile: Podfile
    let lock: PodfileLock
    
    let repoCodes: [String]
    
    init(podfile: Podfile, lock: PodfileLock, repoCodes: [String]) {
        self.podfile = podfile
        self.lock = lock
        self.repoCodes = repoCodes
    }
}

extension Pod {
    private static func checkPodfile(_ path: Path) -> Bool {
        let podfile = path + "Podfile"
        let lock    = path + "Podfile.lock"
        switch (podfile.exists, lock.exists) {
        case (true, true):
            checkCommand()
            return true
        case (true, false):
            print("Need Podfile.lock to check dependencies version")
            exit(1)
        default:
            return false
        }
    }
    
    private static func checkCommand() {
        guard Process.result(Env.pod, arguments: "--version") else {
            print("Need install cocoapod or COCOAPOD=/xxx/pod")
            exit(1)
        }
    }
    
    public static func parse(_ path: Path) async throws -> Pod? {
        guard checkPodfile(path) else { return nil }
        async let podfile = Podfile.process(path + "Podfile")
        let lock = try PodfileLock.parse(path + "Podfile.lock")
        async let codes = lock.repoCodes
        return try await .init(podfile: podfile, lock: lock, repoCodes: codes)
    }
}

extension Pod: Plugin {
    public static func load(_ proj: XCodeProject) async throws -> Pod? {
        return try await parse(proj.workspacePath)
    }
    
    public func workspace() -> String {
        return """
        # rules_pods
        http_archive(
            name = "rules_pods",
            urls = ["https://github.com/pinterest/PodToBUILD/releases/download/4.1.0-412495/PodToBUILD.zip"],
            # sha256 = "",
        )
        
        load("@rules_pods//BazelExtensions:workspace.bzl", "new_pod_repository")
        """
    }
    
    private struct PodPluginTarget: PluginTarget {
        let deps: [String]
        var framework: [String] {
            []
        }
    }
    
    /// "//Vendor/RxSwift:RxSwift",
    /// "//Vendor/Alamofire:Alamofire",
    public subscript(target: String) -> PluginTarget? {
        return PodPluginTarget(deps: podfile[target])
    }
    
    /// bazel run @rules_pods//:update_pods -- --src_root `PWD`
    public func tip() {
        print("""
        use bazel run @rules_pods//:update_pods -- --src_root `PWD` to install pod deps.
        """)
    }

    /// generate Pods.WORKSPACE
    public func generateFile(_ rootPath: Path) throws {
        let code = repoCodes.joined(separator: "\n\n")
        let PodWorkspace = rootPath + "Pods.WORKSPACE"
        print("Create \(PodWorkspace.string)")
//        try to.delete()
        try PodWorkspace.write(code)
    }
}
