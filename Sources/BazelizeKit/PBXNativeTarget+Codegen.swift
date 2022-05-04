//
//  File.swift
//  
//
//  Created by Yume on 2022/4/29.
//

import Foundation
import Cocoapod
import XcodeProj
import PathKit

extension PBXNativeTarget {
    private func generateCode(_ kit: Kit) -> String {
        switch self.productType {
        case .application:
            return generateApplicationCode(kit)
        default:
            return ""
        }
    }
    
    func generate(_ path: Path, _ kit: Kit) throws {
        let code = generateCode(kit)
        let build = path + name + "BUILD"
        try build.write(code)
    }
}
