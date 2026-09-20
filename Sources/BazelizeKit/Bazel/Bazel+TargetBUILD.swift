import Foundation
import PathKit
import Starlark
import Util

extension Bazel {
    /// /{TARGET}/BUILD
    struct TargetBuild: BazelFile {
        // MARK: Lifecycle

        init(_ root: Path, _ target: Target) {
            self.target = target
            targetPath = root + "Targets" + target.name
            path = targetPath + "BUILD"
        }

        // MARK: Internal

        let target: Target

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
}
