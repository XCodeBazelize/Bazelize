import Foundation

public enum TargetResource {
    /// Copied verbatim: the directory is in the bundle under its own name.
    public static var copied: String? {
        guard let url = Bundle.module.url(forResource: "Copied/copied", withExtension: "txt") else { return nil }
        return try? String(contentsOf: url, encoding: .utf8).trimmed
    }

    /// Processed: the file is in the bundle, and where it was is not part of
    /// how it is named.
    public static var processed: String? {
        guard let url = Bundle.module.url(forResource: "processed", withExtension: "txt") else { return nil }
        return try? String(contentsOf: url, encoding: .utf8).trimmed
    }

    /// Embedded in code: no bundle at all, the bytes are a generated source.
    public static var embedded: String {
        String(decoding: PackageResources.greeting_txt, as: UTF8.self).trimmed
    }
}

extension String {
    fileprivate var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
