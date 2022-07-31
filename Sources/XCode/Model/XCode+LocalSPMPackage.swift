//
//  XCode+LocalSPMPackage.swift
//  
//
//  Created by Yume on 2022/7/29.
//

import Foundation
import XcodeProj

extension PBXFileElement {
    var localSPM: [PBXFileElement] {
        if let group = self as? PBXGroup {
            return group.children
                .flatMap(\.localSPM)
        }
        
        if let ref = self as? PBXFileReference, ref.lastKnownFileType == "wrapper" {
            return [ref]
        }
        
        if let ref = self as? PBXFileReference, ref.sourceTree == .sourceRoot {
            return [ref]
        }
        return []
    }
}
