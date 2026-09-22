import Foundation

public let vendorCore = "vendor-kit"

/// Read out of this package's own bundle, not the one using it.
public var vendoredResource: String? {
    guard let url = Bundle.module.url(forResource: "vendored", withExtension: "txt") else { return nil }
    return try? String(contentsOf: url, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
}
