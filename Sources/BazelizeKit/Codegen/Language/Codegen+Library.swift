//
//  Codegen+Library.swift
//
//
//  Created by Yume on 2022/8/23.
//

import Foundation
import XCode

extension Target {
    func generateLibrary(_ kit: Kit) -> String {
        let cFamily = srcs_c + srcs_cpp + srcs_cpp + srcs_objcpp

        switch (cFamily.isEmpty, srcs_swift.isEmpty) {
        case (true, false):
            return generateSwiftLibrary(kit)
        case (false, true):
            return generateObjcLibrary(kit)
        case (false, false):
            #warning("mix objc & swift")
            return ""
        case (true, true):
            return ""
        }
    }
}
