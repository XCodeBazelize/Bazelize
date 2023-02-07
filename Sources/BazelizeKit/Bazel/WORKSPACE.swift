//
//  WORKSPACE.swift
//
//
//  Created by Yume on 2022/4/27.
//

import Foundation
import PathKit
import Util

/// /WORKSPACE
struct Workspace: BazelFile {
    let path: Path
    public let builder = CodeBuilder()

    init(_ root: Path) {
        path = root + "WORKSPACE"
    }

    var code: String {
        builder.build()
    }
}
