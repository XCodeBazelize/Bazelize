import Foundation
import PathKit

extension Bazel {
    /// .bazelversion
    struct Version: BazelFile {
        let path: Path
        let code = "\(Self.bazel.rawValue)"
        static private let bazel: BazelDep.Bazel = .latest

        init(_ root: Path) {
            path = root + ".bazelversion"
        }
    }
}
