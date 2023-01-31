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
    private(set) var code = ""
    public var builder = Build.Builder()

    mutating
    func build() {
        code = builder.build()
    }

    init(_ root: Path) {
        path = root + "WORKSPACE"
    }
}
