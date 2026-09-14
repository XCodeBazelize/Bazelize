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
        source: .init(name: "XCodeProj", url: "https://github.com/MobileNativeFoundation/rules_xcodeproj"),
        tags: [
            try #require(RepoVersionTag(rawTag: "v4.0.1")),
            try #require(RepoVersionTag(rawTag: "4.0.0")),
            try #require(RepoVersionTag(rawTag: "v4.0.1")),
            try #require(RepoVersionTag(rawTag: "3.6.0")),
        ])

    #expect(file.filename == "Repo+XCodeProj.swift")
    #expect(file.content.contains(#"case v4_0_1 = "4.0.1""#))
    #expect(file.content.contains(#"case v4_0_0 = "4.0.0""#))
    #expect(file.content.contains(#"case v3_6_0 = "3.6.0""#))
    #expect(file.content.contains("static let latest: XCodeProj = .v4_0_1"))
    #expect(file.content.firstRange(of: #"case v4_0_1 = "4.0.1""#)?.lowerBound ?? file.content.startIndex <
        file.content.firstRange(of: #"case v4_0_0 = "4.0.0""#)?.lowerBound ?? file.content.endIndex)
}

@Test
func githubErrorIsReadable() async {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    let session = URLSession(configuration: config)

    await MockURLProtocolStorage.shared.setHandler { request in
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

// MARK: - MockURLProtocol

private final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with _: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Task {
            do {
                let (response, data) = try await MockURLProtocolStorage.shared.handler(request)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }
    }

    override func stopLoading() { }
}

// MARK: - MockURLProtocolStorage

private actor MockURLProtocolStorage {
    static let shared = MockURLProtocolStorage()

    private var currentHandler: @Sendable (URLRequest) throws -> (HTTPURLResponse, Data) = { _ in
        fatalError("Handler not set")
    }

    func setHandler(_ handler: @escaping @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)) {
        currentHandler = handler
    }

    func handler(_ request: URLRequest) throws -> (HTTPURLResponse, Data) {
        try currentHandler(request)
    }
}
