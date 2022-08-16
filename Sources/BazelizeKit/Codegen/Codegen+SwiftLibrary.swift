//
//  Codegen+SwiftLibrary.swift
//
//
//  Created by Yume on 2022/7/4.
//

import Foundation
import XCode
import RuleBuilder

extension Target {
    #warning("todo check pure swift, or mix objc & swift")
    func generateSwiftLibrary(_: Kit) -> String {
        #warning("plugin")
//        let depsPod = "" // kit.pod?[name] ?? ""
//        let depsSPM = native.spm_deps

        var builder = Build.Builder()
        builder.load(.swift_library)
        builder.add(.swift_library) {
            "name" => "\(name)_swift"
            "module_name" => name
            "srcs" => srcs
            "deps" => {
////                # Cocoapod Deps
//                // depsPod
////                # XCode SPM Deps
////                depsSPM
////                # Framework TODO (swift_library/objc_library)
                frameworks_library
            }
            StarlarkProperty.Visibility.private
        }
        
        builder.add("alias") {
            "name" => "\(name)_library"
            "actual" => "\(name)_swift"
            StarlarkProperty.Visibility.public
        }

        return builder.build()
    }
}
