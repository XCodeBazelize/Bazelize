//
//  BazelFile.swift
//
//
//  Created by Yume on 2022/12/8.
//

import Foundation
import PathKit

// MARK: - BazelFile

protocol BazelFile {
    var path: Path { get }
    var code: String { get }
}

extension BazelFile {
    func clear() throws {
        try path.delete()
    }

    func write() throws {
        try path.write(code)
    }
}
