import Foundation

/// No bundle is involved: `PackageResources` is generated from the file, and
/// the bytes are in the binary.
public enum TargetEmbed {
    public static var embedded: String {
        String(decoding: PackageResources.greeting_txt, as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
