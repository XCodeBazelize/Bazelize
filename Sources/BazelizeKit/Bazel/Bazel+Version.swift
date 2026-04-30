import Foundation
import PathKit

extension Bazel {
    /// .bazelversion
    struct Version: BazelFile {
        let path: Path
        let code = "\(Self.repo.rawValue)"
        static private let repo: Repo.Bazel = .v9_1_0

        init(_ root: Path) {
            path = root + ".bazelversion"
        }
    }
}
