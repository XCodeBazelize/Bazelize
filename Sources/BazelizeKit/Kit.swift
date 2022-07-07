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
    let projPath: Path
    let pod: Pod?
    let _proj: XcodeProj
    let project: Project
    
    public init(_ projPath: Path) async throws {
        let path = projPath.parent()
        self.path = path
        self.projPath = projPath
        async let pod = Pod.parse(path)
        self._proj = try XcodeProj(path: projPath)
        self.project = .init(proj: self._proj, root: path.string)
        self.pod = try await pod
    }
    
    private func tip() {
        pod?.tip()
    }
    
    public func run(config: String) throws {
        defer { tip() }
        
        for target in project.targets {
            try? target.generate(path, self)
        }
        
        let spm_repositories = project.targets.spm_repositories(projPath)
        let workspace = Workspace { builder in
            builder.default()
//            builder.custom(code: spm_repositories)
        }
        try? workspace.generate(path)
        
        try? pod?.generate(path)
    }
    
    public func dump(config: String) throws {
        for target in project.targets {
            target.dump(config: config)
            print("\n-------------\n")
        }
        
        if project.targets.isHaveSPM {
            print(project.targets.spm_pkgs)
        }
    }
}
