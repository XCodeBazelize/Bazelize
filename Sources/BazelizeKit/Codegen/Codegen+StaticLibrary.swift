//
//  StaticLibrary.swift
//
//
//  Created by Yume on 2023/1/10.
//

import Foundation
import RuleBuilder
import XCode

extension Target {
    func generateStaticLibrary(_ builder: CodeBuilder, _: Kit) {
        builder.add("alias") {
            "name" => "\(name)"
            "actual" => "\(name)_library"
            StarlarkProperty.Visibility.public
        }
    }
}
