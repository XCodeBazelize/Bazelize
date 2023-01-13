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
    func generateStrings(_ builder: inout Build.Builder, _: Kit) {
        let files = allStrings
            .map { label in
                label.delete(prefix: "//\(name):")
            }

        guard !files.isEmpty else { return }

        builder.add("filegroup") {
            "name" => "Strings"
            "srcs" => Starlark.glob(files)
            StarlarkProperty.Visibility.private
        }
    }
}
