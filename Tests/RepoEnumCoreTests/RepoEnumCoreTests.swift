import Foundation
import RepoEnumCore
import Testing

@Test
func parsesOnlyVersionTags() {
    #expect(RepoVersionTag(rawTag: "1.2.3")?.normalizedVersion == "1.2.3")
    #expect(RepoVersionTag(rawTag: "v4.0.1")?.caseName == "v4_0_1")
    #expect(RepoVersionTag(rawTag: "4.0") == nil)
    #expect(RepoVersionTag(rawTag: "release-4.0.1") == nil)
    #expect(RepoVersionTag(rawTag: "4.0.1-beta.1") == nil)
}

@Test
func rendersDescendingAndDeduplicatedEnumCases() throws {
    let file = RepoEnumFile(
        source: .init(name: "XcodeProj", url: "https://github.com/MobileNativeFoundation/rules_xcodeproj"),
        tags: [
            try #require(RepoVersionTag(rawTag: "v4.0.1")),
            try #require(RepoVersionTag(rawTag: "4.0.0")),
            try #require(RepoVersionTag(rawTag: "v4.0.1")),
            try #require(RepoVersionTag(rawTag: "3.6.0")),
        ])

    #expect(file.filename == "BazelDep+XcodeProj.swift")
    #expect(file.content.contains(#"case v4_0_1 = "4.0.1""#))
    #expect(file.content.contains(#"case v4_0_0 = "4.0.0""#))
    #expect(file.content.contains(#"case v3_6_0 = "3.6.0""#))
    #expect(file.content.contains("static let latest: XcodeProj = .v4_0_1"))
    #expect(file.content.firstRange(of: #"case v4_0_1 = "4.0.1""#)?.lowerBound ?? file.content.startIndex <
        file.content.firstRange(of: #"case v4_0_0 = "4.0.0""#)?.lowerBound ?? file.content.endIndex)
}

@Test
func checksummedReleaseNeedsEveryConfiguredAssetDigest() throws {
    let assets = [
        RepoReleaseAsset(os: "darwin", machine: "arm64", asset: "buildifier-darwin-arm64"),
        RepoReleaseAsset(os: "linux", machine: "x86_64", asset: "buildifier-linux-amd64"),
    ]
    let arm64 = String(repeating: "a", count: 64)
    let amd64 = String(repeating: "b", count: 64)

    let complete = RepoChecksummedReleaseVersion(
        release: .init(
            tagName: "v10.1.0",
            assetDigests: [
                "buildifier-darwin-arm64": "sha256:\(arm64)",
                "buildifier-linux-amd64": "sha256:\(amd64)",
            ]),
        assets: assets)
    #expect(complete?.checksums["darwin_arm64"] == arm64)
    #expect(complete?.checksums["linux_x86_64"] == amd64)

    /// A host without a digest is a host the generated code could not pin, so
    /// the whole release is dropped rather than generated half-pinned.
    #expect(RepoChecksummedReleaseVersion(
        release: .init(
            tagName: "v10.1.0",
            assetDigests: ["buildifier-darwin-arm64": "sha256:\(arm64)"]),
        assets: assets) == nil)

    /// A digest GitHub serves in another algorithm is not a SHA-256.
    #expect(RepoChecksummedReleaseVersion(
        release: .init(
            tagName: "v10.1.0",
            assetDigests: [
                "buildifier-darwin-arm64": "sha512:\(arm64)",
                "buildifier-linux-amd64": "sha256:\(amd64)",
            ]),
        assets: assets) == nil)
}

@Test
func rendersEveryHostBesideEachReleaseVersion() throws {
    let first = String(repeating: "c", count: 64)
    let second = String(repeating: "d", count: 64)
    let file = ChecksummedReleaseEnumFile(
        source: .init(name: "Buildifier", url: "https://github.com/bazel-contrib/buildtools"),
        assets: [
            .init(os: "darwin", machine: "arm64", asset: "buildifier-darwin-arm64"),
            .init(os: "linux", machine: "aarch64", asset: "buildifier-linux-arm64"),
        ],
        releases: [
            .init(
                tag: try #require(RepoVersionTag(rawTag: "8.2.1")),
                checksums: ["darwin_arm64": second, "linux_aarch64": first]),
            .init(
                tag: try #require(RepoVersionTag(rawTag: "v10.1.0")),
                checksums: ["darwin_arm64": first, "linux_aarch64": second]),
        ])

    #expect(file.filename == "BazelDep+Buildifier.swift")
    #expect(file.content == """
    extension BazelDep {
        /// https://github.com/bazel-contrib/buildtools
        enum Buildifier: String {
            static let latest: Buildifier = .v10_1_0

            case v10_1_0 = "10.1.0"
            case v8_2_1 = "8.2.1"

            /// A host as `uname` names it, and the asset built for it.
            enum Host: String, CaseIterable {
                case darwin_arm64 = "buildifier-darwin-arm64"
                case linux_aarch64 = "buildifier-linux-arm64"

                /// `uname -s`, lowercased.
                var os: String {
                    switch self {
                    case .darwin_arm64:
                        return "darwin"
                    case .linux_aarch64:
                        return "linux"
                    }
                }

                /// `uname -m`.
                var machine: String {
                    switch self {
                    case .darwin_arm64:
                        return "arm64"
                    case .linux_aarch64:
                        return "aarch64"
                    }
                }
            }

            func sha256(_ host: Host) -> String {
                switch self {
                case .v10_1_0:
                    switch host {
                    case .darwin_arm64:
                        return "\(first)"
                    case .linux_aarch64:
                        return "\(second)"
                    }
                case .v8_2_1:
                    switch host {
                    case .darwin_arm64:
                        return "\(second)"
                    case .linux_aarch64:
                        return "\(first)"
                    }
                }
            }
        }
    }
    """)
}

@Test
func generatedReleasesAreLimitedToRegistryPublishedVersions() async throws {
    let checksum = String(repeating: "e", count: 64)
    let directory = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("repo-enum-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let config = directory.appendingPathComponent("RepoSources.yml")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try """
    - name: Buildifier
      url: https://github.com/bazel-contrib/buildtools
      module: buildifier_prebuilt
      release_assets:
        - os: darwin
          machine: arm64
          asset: buildifier-darwin-arm64
    """.write(to: config, atomically: true, encoding: .utf8)

    let digests = ["buildifier-darwin-arm64": "sha256:\(checksum)"]
    let service = RepoEnumGeneratorService(
        client: StubTagClient(),
        releases: StubReleaseClient(releases: [
            .init(tagName: "v11.0.0", assetDigests: digests),
            .init(tagName: "v10.1.0", assetDigests: digests),
        ]),
        registry: StubRegistryClient(versions: ["10.1.0", "8.2.1"]))

    try await service.generate(configFile: config, outputDirectory: directory)

    let generated = try String(
        contentsOf: directory.appendingPathComponent("BazelDep+Buildifier.swift"),
        encoding: .utf8)
    /// A GitHub release the registry does not serve cannot be a `bazel_dep`
    /// version, so it is never generated — including as `latest`.
    #expect(!generated.contains("v11_0_0"))
    #expect(generated.contains("static let latest: Buildifier = .v10_1_0"))
}

private struct StubTagClient: GitHubTagFetching {
    func tags(for _: String) async throws -> [String] { [] }
}

private struct StubReleaseClient: GitHubReleaseFetching {
    let releases: [GitHubRelease]

    func releases(for _: String) async throws -> [GitHubRelease] { releases }
}

private struct StubRegistryClient: ModuleVersionFetching {
    let versions: [String]

    func versions(forModule _: String) async throws -> [String] { versions }
}

@Test
func githubErrorIsReadable() async {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    let session = URLSession(configuration: config)

    MockURLProtocolStorage.shared.setHandler { request in
        let body = #"{"message":"API rate limit exceeded"}"#.data(using: .utf8)!
        let response = HTTPURLResponse(
            url: try #require(request.url),
            statusCode: 403,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"])!
        return (response, body)
    }

    let client = GitHubTagClient(session: session, token: nil)

    await #expect(throws: RepoEnumGeneratorError.self) {
        _ = try await client.tags(for: "https://github.com/bazelbuild/rules_apple")
    }
}

@Test
func registryVersionsSkipYankedReleases() async throws {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [RegistryMockURLProtocol.self]
    let session = URLSession(configuration: config)

    let client = BazelRegistryClient(session: session)
    let versions = try await client.versions(forModule: "rules_cc")

    #expect(versions == ["0.2.20", "0.2.22"])
}

// MARK: - RegistryMockURLProtocol

/// Serves one fixed BCR metadata payload; kept separate from `MockURLProtocol`
/// so the two network tests can run in parallel without sharing a handler.
private final class RegistryMockURLProtocol: URLProtocol, @unchecked Sendable {
    private static let payload = #"""
    {
        "versions": ["0.2.20", "0.2.21", "0.2.22"],
        "yanked_versions": {"0.2.21": "broken release"}
    }
    """#

    override class func canInit(with _: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(Self.payload.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() { }
}

// MARK: - MockURLProtocol

private final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with _: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        do {
            let (response, data) = try MockURLProtocolStorage.shared.handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() { }
}

// MARK: - MockURLProtocolStorage

private final class MockURLProtocolStorage: @unchecked Sendable {
    static let shared = MockURLProtocolStorage()

    private let lock = NSLock()
    private var currentHandler: @Sendable (URLRequest) throws -> (HTTPURLResponse, Data) = { _ in
        fatalError("Handler not set")
    }

    func setHandler(_ handler: @escaping @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)) {
        lock.withLock { currentHandler = handler }
    }

    func handler(_ request: URLRequest) throws -> (HTTPURLResponse, Data) {
        let handler = lock.withLock { currentHandler }
        return try handler(request)
    }
}
