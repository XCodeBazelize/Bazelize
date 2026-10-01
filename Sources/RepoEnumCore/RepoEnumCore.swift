import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Yams

/// A release asset for one host, named the way `uname` names that host.
public struct RepoReleaseAsset: Codable, Sendable, Equatable {
    /// `uname -s`, lowercased.
    public let os: String
    /// `uname -m`.
    public let machine: String
    /// The asset's file name in the GitHub release.
    public let asset: String

    public init(os: String, machine: String, asset: String) {
        self.os = os
        self.machine = machine
        self.asset = asset
    }

    /// The Swift case this host is generated as.
    public var caseName: String {
        "\(os)_\(machine)"
    }
}

// MARK: - RepoSource

public struct RepoSource: Codable, Sendable, Equatable {
    public let name: String
    public let url: String
    /// Bazel Central Registry module name.
    ///
    /// Present means generated versions must also be published and not yanked
    /// in the registry, because `bazel_dep` can only resolve those versions.
    public let module: String?
    /// GitHub release assets whose API-provided SHA-256 digests are generated
    /// beside each release version.
    public let releaseAssets: [RepoReleaseAsset]?

    public init(
        name: String,
        url: String,
        module: String? = nil,
        releaseAssets: [RepoReleaseAsset]? = nil)
    {
        self.name = name
        self.url = url
        self.module = module
        self.releaseAssets = releaseAssets
    }

    enum CodingKeys: String, CodingKey {
        case name
        case url
        case module
        case releaseAssets = "release_assets"
    }
}

// MARK: - RepoVersionTag

public struct RepoVersionTag: Sendable, Equatable {
    public let normalizedVersion: String
    public let caseName: String
    private let components: [Int]

    public init?(rawTag: String) {
        let pattern = #"^v?(\d+)\.(\d+)\.(\d+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(rawTag.startIndex..<rawTag.endIndex, in: rawTag)
        guard let match = regex.firstMatch(in: rawTag, range: range), match.numberOfRanges == 4 else {
            return nil
        }

        let values = (1..<4).compactMap { index -> Int? in
            guard let range = Range(match.range(at: index), in: rawTag) else { return nil }
            return Int(rawTag[range])
        }

        guard values.count == 3 else { return nil }

        components = values
        normalizedVersion = values.map(String.init).joined(separator: ".")
        caseName = "v" + normalizedVersion.replacingOccurrences(of: ".", with: "_")
    }

    public static func sortDescending(_ lhs: RepoVersionTag, _ rhs: RepoVersionTag) -> Bool {
        lhs.components.lexicographicallyPrecedes(rhs.components) == false && lhs.components != rhs.components
            ? true
            : lhs.components == rhs.components ? lhs.normalizedVersion > rhs.normalizedVersion : false
    }

    public static func sortedDescending(_ tags: [RepoVersionTag]) -> [RepoVersionTag] {
        tags.sorted { lhs, rhs in
            for (left, right) in zip(lhs.components, rhs.components) {
                if left != right {
                    return left > right
                }
            }
            return lhs.normalizedVersion > rhs.normalizedVersion
        }
    }
}

// MARK: - GitHubTagFetching

public protocol GitHubTagFetching: Sendable {
    func tags(for repositoryURL: String) async throws -> [String]
}

public struct GitHubRelease: Sendable, Equatable {
    public let tagName: String
    public let assetDigests: [String: String]

    public init(tagName: String, assetDigests: [String: String]) {
        self.tagName = tagName
        self.assetDigests = assetDigests
    }
}

public protocol GitHubReleaseFetching: Sendable {
    func releases(for repositoryURL: String) async throws -> [GitHubRelease]
}

// MARK: - ModuleVersionFetching

public protocol ModuleVersionFetching: Sendable {
    func versions(forModule module: String) async throws -> [String]
}

// MARK: - RepoEnumGeneratorError

public enum RepoEnumGeneratorError: LocalizedError {
    case invalidArguments(String)
    case invalidGitHubURL(String)
    case githubRequestFailed(statusCode: Int, message: String)
    case noChecksummedReleases(String)
    case registryRequestFailed(module: String, statusCode: Int)

    public var errorDescription: String? {
        switch self {
        case .invalidArguments(let message):
            return message
        case .invalidGitHubURL(let url):
            return "Invalid GitHub repository URL: \(url)"
        case .githubRequestFailed(let statusCode, let message):
            return "GitHub API request failed (\(statusCode)): \(message)"
        case .noChecksummedReleases(let name):
            return "No stable \(name) releases have all configured SHA-256 digests."
        case .registryRequestFailed(let module, let statusCode):
            return "Bazel Central Registry request for \(module) failed (\(statusCode))."
        }
    }
}

// MARK: - RepoEnumFile

public struct RepoEnumFile: Equatable {
    public let source: RepoSource
    public let tags: [RepoVersionTag]

    public init(source: RepoSource, tags: [RepoVersionTag]) {
        var deduplicated: [String: RepoVersionTag] = [:]
        for tag in tags {
            deduplicated[tag.normalizedVersion] = tag
        }

        self.source = source
        self.tags = RepoVersionTag.sortedDescending(Array(deduplicated.values))
    }

    public var filename: String {
        "BazelDep+\(source.name).swift"
    }

    public var content: String {
        let cases = tags.map { #"        case \#($0.caseName) = "\#($0.normalizedVersion)""# }
            .joined(separator: "\n")

        let latest = tags.first.map { tag in
            "        static let latest: \(source.name) = .\(tag.caseName)\n\n"
        } ?? ""

        let body = cases.isEmpty ? "" : "\(latest)\(cases)\n"
        return """
        extension BazelDep {
            /// \(source.url)
            enum \(source.name): String {
        \(body)    }
        }
        """
    }
}

/// A release every configured host has a SHA-256 digest for.
public struct RepoChecksummedReleaseVersion: Sendable, Equatable {
    public let tag: RepoVersionTag
    /// Digest by `RepoReleaseAsset.caseName`.
    public let checksums: [String: String]

    public init?(release: GitHubRelease, assets: [RepoReleaseAsset]) {
        guard let tag = RepoVersionTag(rawTag: release.tagName), !assets.isEmpty else {
            return nil
        }

        var checksums: [String: String] = [:]
        for asset in assets {
            guard let checksum = Self.checksum(release.assetDigests[asset.asset]) else {
                return nil
            }
            checksums[asset.caseName] = checksum
        }

        self.tag = tag
        self.checksums = checksums
    }

    public init(tag: RepoVersionTag, checksums: [String: String]) {
        self.tag = tag
        self.checksums = checksums
    }

    private static func checksum(_ digest: String?) -> String? {
        guard let digest, digest.hasPrefix("sha256:") else { return nil }
        let checksum = String(digest.dropFirst("sha256:".count))
        guard checksum.count == 64, checksum.allSatisfy(\.isHexDigit) else {
            return nil
        }
        return checksum.lowercased()
    }
}

public struct ChecksummedReleaseEnumFile: Equatable {
    public let source: RepoSource
    public let assets: [RepoReleaseAsset]
    public let releases: [RepoChecksummedReleaseVersion]

    public init(
        source: RepoSource,
        assets: [RepoReleaseAsset],
        releases: [RepoChecksummedReleaseVersion])
    {
        var deduplicated: [String: RepoChecksummedReleaseVersion] = [:]
        for release in releases {
            deduplicated[release.tag.normalizedVersion] = release
        }

        self.source = source
        self.assets = assets
        self.releases = deduplicated.values.sorted {
            RepoVersionTag.sortDescending($0.tag, $1.tag)
        }
    }

    public var filename: String {
        "BazelDep+\(source.name).swift"
    }

    public var content: String {
        let cases = releases
            .map { #"        case \#($0.tag.caseName) = "\#($0.tag.normalizedVersion)""# }
            .joined(separator: "\n")
        let latest = releases.first.map { release in
            "        static let latest: \(source.name) = .\(release.tag.caseName)\n\n"
        } ?? ""

        return """
        extension BazelDep {
            /// \(source.url)
            enum \(source.name): String {
        \(latest)\(cases)

                /// A host as `uname` names it, and the asset built for it.
                enum Host: String, CaseIterable {
        \(hostCases)

                    /// `uname -s`, lowercased.
                    var os: String {
                        switch self {
        \(hostProperty(\.os))
                        }
                    }

                    /// `uname -m`.
                    var machine: String {
                        switch self {
        \(hostProperty(\.machine))
                        }
                    }
                }

                func sha256(_ host: Host) -> String {
                    switch self {
        \(checksumCases)
                    }
                }
            }
        }
        """
    }

    private var hostCases: String {
        assets
            .map { #"            case \#($0.caseName) = "\#($0.asset)""# }
            .joined(separator: "\n")
    }

    private func hostProperty(_ keyPath: KeyPath<RepoReleaseAsset, String>) -> String {
        assets.map { asset in
            "                case .\(asset.caseName):\n"
                + "                    return \"\(asset[keyPath: keyPath])\""
        }
        .joined(separator: "\n")
    }

    private var checksumCases: String {
        releases.map { release in
            let hosts = assets.map { asset in
                "                case .\(asset.caseName):\n"
                    + "                    return \"\(release.checksums[asset.caseName] ?? "")\""
            }
            .joined(separator: "\n")

            return "            case .\(release.tag.caseName):\n"
                + "                switch host {\n"
                + hosts + "\n"
                + "                }"
        }
        .joined(separator: "\n")
    }
}

// MARK: - GitHubTagClient

public struct GitHubTagClient: GitHubTagFetching {
    private struct ResponseTag: Decodable {
        let name: String
    }

    private struct ErrorResponse: Decodable {
        let message: String
    }

    private let session: URLSession
    private let token: String?

    public init(
        session: URLSession = .shared,
        token: String? = nil)
    {
        self.session = session
        self.token = token ?? ProcessInfo.processInfo.environment["GITHUB_TOKEN"]?.nilIfEmpty
    }

    public func tags(for repositoryURL: String) async throws -> [String] {
        let repositoryPath = try Self.repositoryPath(from: repositoryURL)
        var page = 1
        var allTags: [String] = []

        while true {
            let url = URL(string: "https://api.github.com/repos/\(repositoryPath)/tags?per_page=100&page=\(page)")!
            var request = URLRequest(url: url)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.setValue("Bazelize RepoEnumPlugin", forHTTPHeaderField: "User-Agent")
            if let token {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }

            let (data, response) = try await session.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                let message = (try? JSONDecoder().decode(ErrorResponse.self, from: data).message)
                    ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                throw RepoEnumGeneratorError.githubRequestFailed(
                    statusCode: httpResponse.statusCode,
                    message: message)
            }

            let tags = try JSONDecoder().decode([ResponseTag].self, from: data)
            if tags.isEmpty {
                break
            }

            allTags.append(contentsOf: tags.map(\.name))
            page += 1
        }

        return allTags
    }

    static func repositoryPath(from repositoryURL: String) throws -> String {
        guard let url = URL(string: repositoryURL), let host = url.host?.lowercased(), host == "github.com" else {
            throw RepoEnumGeneratorError.invalidGitHubURL(repositoryURL)
        }

        let parts = url.pathComponents.filter { $0 != "/" }
        guard parts.count >= 2 else {
            throw RepoEnumGeneratorError.invalidGitHubURL(repositoryURL)
        }

        let owner = parts[0]
        let repo = parts[1].replacingOccurrences(of: ".git", with: "")
        return "\(owner)/\(repo)"
    }
}

// MARK: - GitHubReleaseClient

public struct GitHubReleaseClient: GitHubReleaseFetching {
    private struct ResponseRelease: Decodable {
        struct Asset: Decodable {
            let name: String
            let digest: String?
        }

        let tagName: String
        let draft: Bool
        let prerelease: Bool
        let assets: [Asset]

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case draft
            case prerelease
            case assets
        }
    }

    private struct ErrorResponse: Decodable {
        let message: String
    }

    private let session: URLSession
    private let token: String?

    public init(
        session: URLSession = .shared,
        token: String? = nil)
    {
        self.session = session
        self.token = token ?? ProcessInfo.processInfo.environment["GITHUB_TOKEN"]?.nilIfEmpty
    }

    public func releases(for repositoryURL: String) async throws -> [GitHubRelease] {
        let repositoryPath = try GitHubTagClient.repositoryPath(from: repositoryURL)
        var page = 1
        var result: [GitHubRelease] = []

        while true {
            let url = URL(
                string: "https://api.github.com/repos/\(repositoryPath)/releases?per_page=100&page=\(page)")!
            var request = URLRequest(url: url)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.setValue("Bazelize RepoEnumPlugin", forHTTPHeaderField: "User-Agent")
            if let token {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }

            let (data, response) = try await session.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                let message = (try? JSONDecoder().decode(ErrorResponse.self, from: data).message)
                    ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                throw RepoEnumGeneratorError.githubRequestFailed(
                    statusCode: httpResponse.statusCode,
                    message: message)
            }

            let releases = try JSONDecoder().decode([ResponseRelease].self, from: data)
            if releases.isEmpty { break }

            for release in releases where !release.draft && !release.prerelease {
                var digests: [String: String] = [:]
                for asset in release.assets {
                    if let digest = asset.digest {
                        digests[asset.name] = digest
                    }
                }
                result.append(GitHubRelease(
                    tagName: release.tagName,
                    assetDigests: digests))
            }
            page += 1
        }

        return result
    }
}

// MARK: - BazelRegistryClient

/// Reads published module versions from the Bazel Central Registry.
public struct BazelRegistryClient: ModuleVersionFetching {
    private struct Metadata: Decodable {
        let versions: [String]
        let yanked_versions: [String: String]?
    }

    private let session: URLSession
    private let registry: URL

    public init(
        session: URLSession = .shared,
        registry: URL = URL(string: "https://bcr.bazel.build")!)
    {
        self.session = session
        self.registry = registry
    }

    public func versions(forModule module: String) async throws -> [String] {
        let url = registry
            .appendingPathComponent("modules")
            .appendingPathComponent(module)
            .appendingPathComponent("metadata.json")

        let (data, response) = try await session.data(from: url)

        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            throw RepoEnumGeneratorError.registryRequestFailed(
                module: module,
                statusCode: httpResponse.statusCode)
        }

        let metadata = try JSONDecoder().decode(Metadata.self, from: data)
        let yanked = Set((metadata.yanked_versions ?? [:]).keys)
        return metadata.versions.filter { !yanked.contains($0) }
    }
}

// MARK: - RepoEnumGeneratorService

public struct RepoEnumGeneratorService {
    private let client: GitHubTagFetching
    private let releases: GitHubReleaseFetching
    private let registry: ModuleVersionFetching
    private let decoder = YAMLDecoder()
    private let fileManager = FileManager.default

    public init(
        client: GitHubTagFetching = GitHubTagClient(),
        releases: GitHubReleaseFetching = GitHubReleaseClient(),
        registry: ModuleVersionFetching = BazelRegistryClient())
    {
        self.client = client
        self.releases = releases
        self.registry = registry
    }

    public func generate(configFile: URL, outputDirectory: URL) async throws {
        let data = try Data(contentsOf: configFile)
        let sources = try decoder.decode([RepoSource].self, from: String(decoding: data, as: UTF8.self))

        try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

        for source in sources {
            let (filename, content) = if let assets = source.releaseAssets {
                try await checksummedFile(for: source, assets: assets)
            } else {
                try await versionFile(for: source)
            }
            let fileURL = outputDirectory.appendingPathComponent(filename)
            /// A Swift file ends in a newline, here as everywhere else in the
            /// package.
            try (content + "\n").write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }

    private func versionFile(for source: RepoSource) async throws -> (String, String) {
        let rawVersions = if let module = source.module {
            try await registry.versions(forModule: module)
        } else {
            try await client.tags(for: source.url)
        }
        let file = RepoEnumFile(
            source: source,
            tags: rawVersions.compactMap(RepoVersionTag.init(rawTag:)))
        return (file.filename, file.content)
    }

    /// A release is generated only when its binaries carry the digests the
    /// generated code pins, and — when the source names a module — only when
    /// the Bazel Central Registry serves that version too.
    private func checksummedFile(
        for source: RepoSource,
        assets: [RepoReleaseAsset]) async throws -> (String, String)
    {
        let published: Set<String>? = if let module = source.module {
            Set(try await registry.versions(forModule: module)
                .compactMap { RepoVersionTag(rawTag: $0)?.normalizedVersion })
        } else {
            nil
        }

        let versions = try await releases.releases(for: source.url)
            .compactMap { RepoChecksummedReleaseVersion(release: $0, assets: assets) }
            .filter { published?.contains($0.tag.normalizedVersion) ?? true }

        guard !versions.isEmpty else {
            throw RepoEnumGeneratorError.noChecksummedReleases(source.name)
        }

        let file = ChecksummedReleaseEnumFile(
            source: source,
            assets: assets,
            releases: versions)
        return (file.filename, file.content)
    }
}

// MARK: - RepoEnumPaths

public enum RepoEnumPaths {
    public static func resolve(_ path: String, from base: URL, isDirectory: Bool = false) -> URL {
        let url = URL(fileURLWithPath: path, isDirectory: isDirectory)
        return url.path.hasPrefix("/") ? url : base.appendingPathComponent(path, isDirectory: isDirectory)
    }
}

extension String {
    fileprivate var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
