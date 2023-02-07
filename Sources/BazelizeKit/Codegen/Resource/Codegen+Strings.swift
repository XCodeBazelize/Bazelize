//
//  String.swift
//
//
//  Created by Yume on 2023/1/9.
//

import Foundation
import RuleBuilder
import XCode

extension Target {
    func generateStrings(_ builder: CodeBuilder, _: Kit) {
        let files = allStrings

        guard !files.isEmpty else { return }

        builder.add("filegroup") {
            "name" => "Strings"
            "srcs" => files
            StarlarkProperty.Visibility.private
        }
    }
}
