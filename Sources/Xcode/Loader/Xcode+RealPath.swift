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
        guard let resolved = realpath(self, nil) else { return self }
        defer { free(resolved) }
        return String(cString: resolved)
    }
}

extension Path {
    var realPath: Path {
        Path(string.realPath)
    }
}
