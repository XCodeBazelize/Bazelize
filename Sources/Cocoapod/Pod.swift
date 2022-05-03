//
//  File.swift
//  
//
//  Created by Yume on 2022/4/26.
//

import Foundation
import Util
import PathKit

public struct Pod {
    let podfile: Podfile
    let lock: PodfileLock
    let specs: [PodSpec]
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
        async let specs = lock.specs
        return try await .init(podfile: podfile, lock: lock, specs: specs)
    }
}

extension Pod {
    /// "//Vendor/RxSwift:RxSwift",
    /// "//Vendor/Alamofire:Alamofire",
    public subscript(targetName: String) -> String {
        return podfile[targetName]
    }
    
    public func tip() {
        print("""
        use bazel run @rules_pods//:update_pods -- --src_root `PWD` to install pod deps.
        """)
    }

    /// generate Pods.WORKSPACE
    public func generate(_ path: Path) throws {
        let to = path + "Pods.WORKSPACE"
        let code = specs.map(\.code).joined(separator: "\n\n")
//        try to.delete()
        try to.write(code)
    }
}
