//
//  WORKSPACE.swift
//
//
//  Created by Yume on 2022/4/27.
//

import Foundation
import PathKit

struct Workspace {
    // MARK: Lifecycle

    public init(_ build: (inout Builder) -> Void) {
        var builder = Builder()
        build(&builder)
        code = builder.build()
    }

    public init() {
        var builder = Builder()
        builder.default()
        code = builder.build()
    }

    // MARK: Public

    // WORKSPACE
    public func generate(_ path: Path) throws {
        let workspace = path + "WORKSPACE"
        print("Create \(workspace.string)")
//        try _workspace.delete()
        try workspace.write(code)
    }

    // MARK: Private

    private let code: String
}
