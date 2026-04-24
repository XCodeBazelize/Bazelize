//
//  StaticLibrary.swift
//
//
//  Created by Yume on 2023/1/10.
//

import BazelRules
import Foundation
import Starlark
import XCode

extension Target {
    func generateStaticLibrary(_ builder: CodeBuilder, _: Kit) {
        builder.call(
            Rules.Builtin.Call.alias(
                name: name,
                actual: .named("\(name)_library"),
                visibility: .public))
    }
}
