//
//  WORKSPACE.swift
//
//
//  Created by Yume on 2022/4/27.
//

import Foundation
import PathKit
import Util

struct Workspace: BazelFile {
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


    // MARK: Public

    // WORKSPACE
    public func generate(_ path: Path) throws {
        let workspace = path + "WORKSPACE"
        Log.codeGenerate.info("Create `Workspace` at \(workspace.string, privacy: .public)")
//        try _workspace.delete()
        try workspace.write(code)
    }

    // MARK: Internal

    let path: Path
    let code: String
}
