//
//  File.swift
//  
//
//  Created by Yume on 2022/4/29.
//

import Foundation
import Cocoapod
import XCode
import PathKit
import Util
import XcodeProj
import CoreLocation

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
    
    public func run() async throws {
        defer { tip() }
        
        for target in proj.pbxproj.nativeTargets {
            try target.generate(path, self)
        }
        
        try Workspace.generate(path)
        try pod?.generate(path)
        
        print("over")
        
    }
}
