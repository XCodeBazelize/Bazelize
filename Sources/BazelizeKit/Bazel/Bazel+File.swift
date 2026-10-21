import Foundation
import PathKit

// MARK: - BazelFile

protocol BazelFile {
    var path: Path { get }
    var code: String { get }
}

extension BazelFile {
    /// The header, the code, and one newline.
    ///
    /// A file that ends without a newline, or with a blank line, is a
    /// formatting report from `bazel run //:lint` every time it is written.
    func write() throws {
        let body = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else {
            return try path.write(generationHeader + "\n")
        }
        return try path.write(generationHeader + "\n\n" + body + "\n")
    }
}

extension Bazel {
    typealias File = BazelFile
}

private let generationMarker = "Generated using Bazelize"
private let url = "https://github.com/XCodeBazelize/Bazelize"
private let generationHeader = "# \(generationMarker) \(version) - \(url)"
