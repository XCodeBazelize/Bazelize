//
//  WORKSPACE.swift
//
//
//  Created by Yume on 2022/4/27.
//

import Foundation
import PathKit

struct Workspace: BazelFile {
    let path: Path
    let code: String
    // MARK: Lifecycle

    init(_ root: Path, _ build: (inout Builder) -> Void) {
        var builder = Builder()
        build(&builder)
        code = builder.build()
        path = root + "WORKSPACE"
    }

    init(_ root: Path) {
        var builder = Builder()
        builder.default()
        code = builder.build()
        path = root + "WORKSPACE"
    }
}
