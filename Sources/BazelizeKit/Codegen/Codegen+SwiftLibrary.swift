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

        #warning("")
        let depsPod: String = ""//kit.pod?[name] ?? ""
        let depsSPM = native.spm_deps
        
        var builder = Build.Builder()
        builder.load(.swift_library)
        builder.custom("""
        swift_library(
            name = "\(name)_swift",
            module_name = "\(name)",
            srcs = [
        \(srcs.withNewLine.indent(2))
            ],
            deps = [
                # Cocoapod Deps
        \(depsPod.indent(2))

                # XCode SPM Deps
        \(depsSPM.indent(1, "# ").indent(2))
        
                # Framework TODO (swift_library/objc_library)
        \(self.frameworks_library.withNewLine.indent(2))
            ],
            visibility = ["//visibility:private"],
        )
        alias(
            name = "\(name)_library",
            actual = "\(name)_swift",
            visibility = ["//visibility:public"],
        )
        """)

        return builder.build()
    }
}
