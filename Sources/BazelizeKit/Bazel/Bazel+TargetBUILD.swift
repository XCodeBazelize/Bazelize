import Foundation
import PathKit
import Starlark
import Util

extension Bazel {
    /// /{TARGET}/BUILD
    struct TargetBuild: BazelFile {
        // MARK: Lifecycle

        /// The target stays owned by `kit.project`; the file keeps its position
        /// and borrows it again when the code is generated.
        init(_ root: Path, _ target: borrowing Target, at index: Int) {
            targetIndex = index
            targetPath = root + "Targets" + target.name
            path = targetPath + "BUILD"
        }

        // MARK: Internal

        let targetIndex: Int

        let path: Path
        let targetPath: Path
        private(set) var code = ""


        mutating
        func setup(_ kit: Kit) throws {
            code = try kit.project.targets[targetIndex].generateCode(kit)
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
