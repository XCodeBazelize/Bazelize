import Foundation

/// A library's own bundle, read by whoever links it. A program has no Apple
/// bundler to embed this one, so it only resolves when the bundle travels with
/// the executable.
public enum Support {
    public static func text() throws -> String {
        guard let url = Bundle.module.url(forResource: "support", withExtension: "txt") else {
            fatalError("missing resource: support.txt")
        }
        return try String(contentsOf: url, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
