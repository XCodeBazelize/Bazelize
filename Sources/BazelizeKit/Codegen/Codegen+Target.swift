//
//  Target+Codegen.swift
//  
//
//  Created by Yume on 2022/4/29.
//

import Foundation
import Cocoapod
import XCode
import PathKit

extension Target {
    private func generateCode(_ kit: Kit) -> String {
        switch self.native.productType {
        case .application:
            return generateApplicationCode(kit)
        case .commandLineTool:
            return generateCommandLineApplicationCode(kit)
        case .framework:
            return generateFrameworkCode(kit)
        case .staticFramework: fallthrough
//            return "" //generateStaitcFrameworkCode(kit)
        case .appExtension: fallthrough
        case .unitTestBundle: fallthrough
        default:
            print("""
            Name: \(name)
            Type: \(self.native.productType?.rawValue ?? "") not gen
            """)
            return ""
        }
    }
    
    /// WORKSPACE/TARGET_NAME/BUILD
    public func generateBUILD(_ kit: Kit) throws {
        let code = generateCode(kit)
        let build = kit.project.workspacePath + name + "BUILD"
        print("Create \(build.string)")
        try build.write(code)
    }
}
