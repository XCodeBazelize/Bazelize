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
