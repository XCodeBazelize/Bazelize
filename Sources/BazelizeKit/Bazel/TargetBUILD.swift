//
//  TargetBUILD.swift
//
//
//  Created by Yume on 2022/12/8.
//


import Foundation
import PathKit
import PluginInterface
import RuleBuilder
import Util
import XCode

/// /{TARGET}/BUILD
struct TargetBuild: BazelFile {
    // MARK: Lifecycle

    init(_ root: Path, _ target: XCode.Target) {
        self.target = target
        targetPath = root + target.name
        path = targetPath + "BUILD"
    }

    // MARK: Internal

    let target: XCode.Target

    let path: Path
    let targetPath: Path
    private(set) var code = ""


    mutating
    func setup(_ kit: Kit) {
        code = target.generateCode(kit)
    }

    func mkpath() throws {
        do {
            try targetPath.mkpath()
        } catch {
            Log.codeGenerate.error("Fail to create dir \(targetPath.string)")
            throw error
        }
    }
}
