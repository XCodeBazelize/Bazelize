//
//  File.swift
//  
//
//  Created by Yume on 2022/4/21.
//

import Foundation
import XcodeProj

public protocol Project {
    var targets: [Target] {get}
}

extension PBXProj: Project {
    public var targets: [Target] {
        return nativeTargets
    }
}
