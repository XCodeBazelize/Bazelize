//
//  Codegen+Library.swift
//
//
//  Created by Yume on 2022/8/23.
//

import Foundation
import XCode

extension Target {
    func generateLibrary(_ builder: inout Build.Builder, _ kit: Kit) {
        let cFamily = srcs_c + srcs_cpp + srcs_objc + srcs_objcpp

        switch (cFamily.isEmpty, srcs_swift.isEmpty) {
        case (true, false):
            generateSwiftLibrary(&builder, kit)
        case (false, true):
            generateObjcLibrary(&builder, kit)
        case (false, false):
            #warning("mix objc & swift")
            print("")
        case (true, true):
            print("")
        }
    }
}
