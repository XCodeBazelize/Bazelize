import Foundation

public enum TargetResource {
    /// Copied verbatim: the directory is in the bundle under its own name.
    public static var copied: String? {
        guard let url = Bundle.module.url(forResource: "Copied/copied", withExtension: "txt") else { return nil }
        return try? String(contentsOf: url, encoding: .utf8).trimmed
    }

    /// A copied file, which keeps its name and nothing above it.
    public static var copiedFile: String? {
        guard let url = Bundle.module.url(forResource: "single", withExtension: "txt") else { return nil }
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

    /// The explicitly localized resource: declared with `localization:`, so it
    /// is filed under the package's default localization.
    public static var explicitLocalization: String? {
        guard let url = Bundle.module.url(forResource: "Explicit", withExtension: "strings") else { return nil }
        return try? String(contentsOf: url, encoding: .utf8).trimmed
    }

    /// A `.lproj` directory is a localization without anything being declared.
    public static var lprojLocalization: String {
        NSLocalizedString("lproj", bundle: .module, comment: "")
    }

    /// The same key in whichever localization is asked for: a bundle with two
    /// of them answers each, which one with only a fallback cannot.
    public static func lprojLocalization(_ language: String) -> String? {
        guard let path = Bundle.module.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path)
        else {
            return nil
        }
        return bundle.localizedString(forKey: "lproj", value: nil, table: nil)
    }

    /// What is in the bundle, by name. A platform resource is compiled by
    /// whoever builds it — `Assets.car`, `Panel.nib`, `default.metallib` — and
    /// copied as it is by whoever cannot, so both names are the same resource
    /// having arrived.
    public static var bundled: Set<String> {
        guard let root = Bundle.module.resourceURL,
              let entries = try? FileManager.default.subpathsOfDirectory(atPath: root.path)
        else {
            return []
        }
        return Set(entries)
    }
}

extension String {
    fileprivate var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
