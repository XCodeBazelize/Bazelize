//
//  Target+Codegen.swift
//
//
//  Created by Yume on 2022/4/29.
//

import Foundation
import PathKit
import XCode

extension Target {
    // MARK: Internal

    /// WORKSPACE/TARGET_NAME/BUILD
    internal func generateBUILD(_ kit: Kit) throws {
        let code = generateCode(kit)
        let build = kit.project.workspacePath + name + "BUILD"
        print("Create \(build.string)")
        try build.write(code)
    }

    // MARK: Private

    private func generateCode(_ kit: Kit) -> String {
        var builder = Build.Builder()
        generateLibrary(&builder, kit)

        generateLoadPlistFragment(&builder)
        generatePlistFile(&builder, kit)
        generatePlistAuto(&builder)
        generatePlistDefault(&builder)

        switch native.productType {
        case .application:
            generateApplicationCode(&builder, kit)
        case .commandLineTool:
            generateCommandLineApplicationCode(&builder, kit)
        case .framework:
            generateFrameworkCode(&builder, kit)
        case .staticFramework: fallthrough
//            return "" //generateStaitcFrameworkCode(kit)
        case .appExtension: fallthrough
        case .unitTestBundle: fallthrough
        default:
            print("""
            Name: \(name)
            Type: \(native.productType?.rawValue ?? "") not gen
            """)
        }
        return builder.build()
    }
}
