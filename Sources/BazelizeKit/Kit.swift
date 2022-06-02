//
//  Kit.swift
//
//
//  Created by Yume on 2022/4/29.
//

import Cocoapod
import CoreLocation
import Foundation
import PathKit
import Util
import XCode
import XcodeProj

public struct Kit {
    let path: Path
    let pod: Pod?
    let proj: XcodeProj
    
    public init(_ projPath: Path) async throws {
        let path = projPath.parent()
        self.path = path
        async let pod = Pod.parse(path)
        self.proj = try XcodeProj(path: projPath)
        self.pod = try await pod
    }
    
    private func tip() {
        pod?.tip()
    }
    
    public func run() throws {
        defer { tip() }
        
        for target in proj.pbxproj.nativeTargets {
            try? target.generate(path, self)
        }
        
        try? Workspace.generate(
            path,
            other: proj.pbxproj.nativeTargets.spm_repositories
        )
        try? pod?.generate(path)
    }
    
    public func dump() throws {
        for target in proj.pbxproj.nativeTargets {
            target.dump()
            print("\n-------------\n")
        }
        
        if proj.pbxproj.nativeTargets.isHaveSPM {
            print(proj.pbxproj.nativeTargets.spm_pkgs)
        }
    }
}
