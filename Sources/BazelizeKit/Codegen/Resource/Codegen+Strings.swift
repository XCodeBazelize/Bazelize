//
//  String.swift
//
//
//  Created by Yume on 2023/1/9.
//

import Foundation
import RuleBuilder
import BazelRules
import XCode

extension Target {
    func generateStrings(_ builder: CodeBuilder, _: Kit) {
        let files = allStrings

        guard !files.isEmpty else { return }

        builder.call(
            Rules.Builtin.Call.filegroup(
                name: "Strings",
                srcs: .build {
                    files
                },
                visibility: .private
            )
        )
    }
}
