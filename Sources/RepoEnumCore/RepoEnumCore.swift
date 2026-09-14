import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Yams

// MARK: - RepoSource

public struct RepoSource: Codable, Sendable, Equatable {
    public let name: String
    public let url: String

    public init(name: String, url: String) {
        self.name = name
        self.url = url
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

// MARK: - RepoEnumGeneratorError

public enum RepoEnumGeneratorError: LocalizedError {
    case invalidArguments(String)
    case invalidGitHubURL(String)
    case githubRequestFailed(statusCode: Int, message: String)

    public var errorDescription: String? {
        switch self {
        case .invalidArguments(let message):
            return message
        case .invalidGitHubURL(let url):
            return "Invalid GitHub repository URL: \(url)"
        case .githubRequestFailed(let statusCode, let message):
            return "GitHub API request failed (\(statusCode)): \(message)"
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

// MARK: - RepoEnumGeneratorService

public struct RepoEnumGeneratorService {
    private let client: GitHubTagFetching
    private let decoder = YAMLDecoder()
    private let fileManager = FileManager.default

    public init(client: GitHubTagFetching = GitHubTagClient()) {
        self.client = client
    }

    public func generate(configFile: URL, outputDirectory: URL) async throws {
        let data = try Data(contentsOf: configFile)
        let sources = try decoder.decode([RepoSource].self, from: String(decoding: data, as: UTF8.self))

        try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

        for source in sources {
            let rawTags = try await client.tags(for: source.url)
            let tags = rawTags.compactMap(RepoVersionTag.init(rawTag:))
            let file = RepoEnumFile(source: source, tags: tags)
            let fileURL = outputDirectory.appendingPathComponent(file.filename)
            try file.content.write(to: fileURL, atomically: true, encoding: .utf8)
        }
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
