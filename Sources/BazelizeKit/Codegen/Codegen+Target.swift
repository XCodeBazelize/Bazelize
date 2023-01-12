//
//  Target+Codegen.swift
//
//
//  Created by Yume on 2022/4/29.
//

import Foundation
import PathKit
import Util
import XCode

extension Target {
    var isTest: Bool {
        switch native.productType {
        case .unitTestBundle: fallthrough
        case .ocUnitTestBundle: fallthrough
        case .uiTestBundle:
            return true
        default: return false
        }
    }

    func generateCode(_ kit: Kit) -> String {
        var builder = Build.Builder()
        generateLibrary(&builder, kit)

        generateLoadPlistFragment(&builder)
        generatePlistFile(&builder, kit)
        generatePlistAuto(&builder)
        generatePlistDefault(&builder)

        let name = name
        let native = native

        switch native.productType {
        case .application:
            generateStrings(&builder, kit)
            generateApplicationCode(&builder, kit)
        case .commandLineTool:
            generateCommandLineApplicationCode(&builder, kit)
        case .framework:
            generateFrameworkCode(&builder, kit)
//        case .staticFramework: break
        case .staticLibrary:
            generateStaticLibrary(&builder, kit)
//        case .appExtension: break
        case .unitTestBundle:
            generateUnitTest(&builder, kit)
        case .uiTestBundle:
            generateUITest(&builder, kit)
        default:
            Log.codeGenerate.warning("""
            Name: \(name, privacy: .public)
            Type: \(native.productType?.rawValue ?? "") not gen
            """)
        }
        return builder.build()
    }
}
