import Foundation

func contents(_ name: String, extension ext: String, subdirectory: String? = nil) throws -> String {
    guard
        let url = Bundle.module.url(
            forResource: name,
            withExtension: ext,
            subdirectory: subdirectory)
    else {
        fatalError("missing resource: \(name).\(ext)")
    }
    return try String(contentsOf: url, encoding: .utf8)
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

guard
    try contents("copied", extension: "txt", subdirectory: "Copied") == "copied",
    try contents("processed", extension: "txt") == "processed",
    Bundle.module.url(forResource: "PrivacyInfo", withExtension: "xcprivacy") != nil,
    Bundle.module.url(forResource: "Assets", withExtension: "car") != nil
else {
    fatalError("resource bundle contents differ from SwiftPM")
}

print("executable resources ok")
