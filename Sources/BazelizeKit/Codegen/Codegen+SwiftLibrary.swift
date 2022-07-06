//
//  Codegen+SwiftLibrary.swift
//  
//
//  Created by Yume on 2022/7/4.
//

import Foundation
import XCode

extension Target {
    func generateSwiftLibrary(_ kit: Kit) -> String {
        #warning("todo check pure swift, or mix objc & swift")

        let depsPod: String = kit.pod?[name] ?? ""
        let depsSPM = native.spm_deps
        
        var builder = Build.Builder()
        builder.load(.swift_library)
        builder.custom("""
        swift_library(
            name = "_\(name)",
            module_name = "\(name)",
            srcs = [
        \(srcs.indent(2))
            ],
            deps = [
                # Cocoapod Deps
        \(depsPod.indent(2))

                # XCode SPM Deps
        \(depsSPM.indent(2))
            ],
            visibility = ["//visibility:public"],
        )
        """)

        return builder.build()
    }
}
