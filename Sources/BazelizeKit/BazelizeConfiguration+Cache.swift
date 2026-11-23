import Foundation
import PathKit

extension BazelizeConfiguration {
    public struct Cache: Equatable, Sendable {
        public let disk: String?
        public let repository: String?
        public let remote: String?
        public let uploadLocalResults: Bool?

        public init() {
            disk = nil
            repository = nil
            remote = nil
            uploadLocalResults = nil
        }

        public init(
            disk: String?,
            repository: String?,
            remote: String?,
            uploadLocalResults: Bool?,
            relativeTo base: Path = .current) throws
        {
            for (key, value) in [("disk", disk), ("repository", repository), ("remote", remote)] {
                if let value, value.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) {
                    throw CacheError.invalidValue(key)
                }
            }
            if let remote, !remote.isEmpty {
                guard
                    let url = URLComponents(string: remote),
                    ["http", "https", "grpc", "grpcs"].contains(url.scheme ?? ""),
                    let host = url.host, !host.isEmpty,
                    url.user == nil, url.password == nil
                else { throw CacheError.invalidValue("remote (expected an HTTP(S) or gRPC(S) endpoint without credentials)") }
            }
            self.disk = disk.map { $0.isEmpty ? "" : (base + Path($0)).absolute().normalize().string }
            self.repository = repository.map { $0.isEmpty ? "" : (base + Path($0)).absolute().normalize().string }
            self.remote = remote
            self.uploadLocalResults = uploadLocalResults
        }

        var rc: String {
            var lines: [String] = []
            for (flag, value) in [("disk_cache", disk), ("repository_cache", repository), ("remote_cache", remote)] {
                if let value {
                    let quoted = value.replacingOccurrences(of: "\\", with: "\\\\")
                        .replacingOccurrences(of: "\"", with: "\\\"")
                    lines.append("build --\(flag)=\"\(quoted)\"")
                }
            }
            if let uploadLocalResults {
                lines.append("build --remote_upload_local_results=\(uploadLocalResults)")
            }
            return lines.isEmpty ? "" : lines.joined(separator: "\n") + "\n"
        }
    }

    /// Command-line paths are relative to the invocation directory; YAML paths
    /// have already been resolved relative to the selected configuration file.
    public func overridingCache(
        disk: String?, repository: String?, remote: String?, uploadLocalResults: Bool?) throws
        -> Self
    {
        Self(schema: schema, buildifier: buildifier, cache: try Cache(
            disk: disk ?? cache.disk,
            repository: repository ?? cache.repository,
            remote: remote ?? cache.remote,
            uploadLocalResults: uploadLocalResults ?? cache.uploadLocalResults))
    }
}

// MARK: - CacheError

private enum CacheError: Error, LocalizedError {
    case invalidValue(String)

    var errorDescription: String? {
        switch self {
        case .invalidValue(let key): "Invalid cache.\(key) setting."
        }
    }
}
