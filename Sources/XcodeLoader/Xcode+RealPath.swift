import Foundation
import PathKit

extension String {
    /// The same file, spelled with every symlink resolved.
    ///
    /// Two spellings of one path do not compare equal, and the project root and
    /// the files under it do not always arrive spelled the same way: `/tmp` is a
    /// link to `/private/tmp`, and a file resolved through XcodeProj can keep the
    /// link where the root has already lost it. A file that then fails to look
    /// like it is under the root loses its path entirely, and what it generates
    /// is a glob matching nothing.
    ///
    /// Not `resolvingSymlinksInPath()`: that one drops a leading `/private`,
    /// which is the prefix `/tmp` resolves to.
    var realPath: String {
        if let resolved = realpath(self, nil) {
            defer { free(resolved) }
            return String(cString: resolved)
        }
        // realpath requires the leaf to exist. Resolve the nearest existing
        // ancestor so a missing file keeps its project-relative path too.
        let path = Path(self).normalize()
        let parent = path.parent()
        guard parent != path else { return path.string }
        return (Path(parent.string.realPath) + path.lastComponent).string
    }
}

extension Path {
    var realPath: Path {
        Path(string.realPath)
    }
}
