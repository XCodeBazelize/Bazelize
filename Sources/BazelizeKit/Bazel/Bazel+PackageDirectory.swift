import PathKit

extension Bazel {
    /// A generated Bazel package and the BUILD file it owns.
    struct PackageDirectory {
        let root: Path
        let build: Path

        init(_ root: Path) {
            self.root = root
            build = root + "BUILD"
        }
    }
}
