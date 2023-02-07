//
//  Codegen+Library.swift
//
//
//  Created by Yume on 2022/8/23.
//

import Foundation
import Util
import XCode

extension Target {
    func generateLibrary(_ builder: CodeBuilder, _ kit: Kit) {
        let name = name
        let cFamily = srcs_c + srcs_cpp + srcs_objc + srcs_objcpp

        generateAssets(builder, kit)

        switch (cFamily.isEmpty, srcs_swift.isEmpty) {
        case (true, false):
            generateSwiftLibrary(builder, kit)
        case (false, true):
            generateObjcLibrary(builder, kit)
        case (false, false):
            /// TODO: mix objc & swift
            Log.codeGenerate.warning("TODO: mix objc & swift")
        case (true, true):
            Log.codeGenerate.warning("Target(\(name, privacy: .public)) can't happen")
        }
    }
}
