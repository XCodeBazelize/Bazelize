import PathKit
import Xcode

extension Xcode.Project {
    /// Loads an `.xcodeproj`, or a `Package.swift` described as a project with no
    /// targets of its own.
    public static func load(path: Path, preferConfig: String?) async throws -> Self {
        if let manifest = manifest(at: path) {
            return package(at: manifest)
        }

        return try await ProjectLoader(path: path, preferConfig: preferConfig).model()
    }
}
