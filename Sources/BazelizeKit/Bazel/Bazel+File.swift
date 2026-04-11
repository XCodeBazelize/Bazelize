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
        try path.write(generationHeader + "\n\n" + code)
    }
}

extension Bazel {
    typealias File = BazelFile
}

private let generationMarker = "Generated using Bazelize"
private let url = "https://github.com/XCodeBazelize/Bazelize"
private let generationHeader = "# \(generationMarker) \(version) - \(url)"
