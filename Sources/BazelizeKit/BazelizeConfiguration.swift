import Foundation
import PathKit
import Yams

public struct BazelizeConfiguration: Equatable, Sendable {
    public static let fileName = "bazelize.yaml"

    /// The buildifier release a generated `//:lint` downloads, taken from the
    /// generated catalog so a version and its checksums are never spelled by
    /// hand.
    public struct Buildifier: Equatable, Sendable {
        public var version: String { release.rawValue }

        /// The shell `case` arms a generated lint command picks its download
        /// with: one per host the catalog has a checksum for.
        var hostCases: String {
            BazelDep.Buildifier.Host.allCases.map { host in
                """
                    \(host.os)/\(host.machine))
                        asset="\(host.rawValue)"
                        sha256="\(release.sha256(host))"
                        ;;
                """
            }
            .joined(separator: "\n")
        }

        fileprivate static let current = Buildifier(release: .latest)

        private let release: BazelDep.Buildifier

        fileprivate init(release: BazelDep.Buildifier) {
            self.release = release
        }
    }

    public static let `default` = BazelizeConfiguration(
        schema: 1,
        buildifier: .current)

    public static let example = """
    schema: 1

    buildifier:
      version: "\(Buildifier.current.version)"
    """ + "\n"

    public let schema: Int
    public let buildifier: Buildifier

    private init(schema: Int, buildifier: Buildifier) {
        self.schema = schema
        self.buildifier = buildifier
    }

    /// Writes the example at `destination`: inside it when that names a
    /// directory, and as the file itself when it names a YAML file — `-o .`
    /// and `-o config/custom.yaml` both land where they are read from.
    @discardableResult
    public static func createExample(at destination: Path) throws -> Path {
        let destination = destination.absolute().normalize()
        /// A path that does not exist yet is a directory unless it is spelled
        /// as a YAML file: `-o nested/project` makes the directory rather than
        /// a file called `project`.
        let namesFile = ["yaml", "yml"].contains(destination.extension ?? "")
        let path = destination.isDirectory || !namesFile
            ? destination + fileName
            : destination

        guard !path.exists else {
            throw BazelizeConfigurationError.fileAlreadyExists(path.string)
        }

        try path.parent().mkpath()
        do {
            try Data(example.utf8).write(to: path.url, options: .withoutOverwriting)
        } catch {
            guard !path.exists else {
                throw BazelizeConfigurationError.fileAlreadyExists(path.string)
            }
            throw error
        }
        return path
    }

    public static func load(explicitPath: Path?, inputPath: Path) throws -> BazelizeConfiguration {
        let path: Path
        if let explicitPath {
            path = explicitPath.absolute().normalize()
            guard path.exists else {
                throw BazelizeConfigurationError.fileNotFound(path.string)
            }
        } else {
            path = automaticPath(for: inputPath)
            guard path.exists else { return .default }
        }

        do {
            let yaml = try String(contentsOfFile: path.string, encoding: .utf8)
            let document = try YAMLDecoder().decode(Document.self, from: yaml)
            guard let release = BazelDep.Buildifier(rawValue: document.buildifier.version) else {
                throw DocumentError.unsupportedBuildifier(document.buildifier.version)
            }
            let buildifier = Buildifier(release: release)
            return BazelizeConfiguration(schema: document.schema, buildifier: buildifier)
        } catch {
            throw BazelizeConfigurationError.invalidFile(
                path.string,
                Self.description(of: error))
        }
    }

    private static func automaticPath(for inputPath: Path) -> Path {
        let inputPath = inputPath.absolute().normalize()
        if inputPath.lastComponent == "Package.swift" {
            return inputPath.parent() + fileName
        }
        if inputPath.isDirectory, (inputPath + "Package.swift").exists {
            return inputPath + fileName
        }
        return inputPath.parent() + fileName
    }

    private static func description(of error: Error) -> String {
        let context: DecodingError.Context?
        switch error {
        case let DecodingError.dataCorrupted(value):
            context = value
        case let DecodingError.keyNotFound(_, value):
            context = value
        case let DecodingError.typeMismatch(_, value):
            context = value
        case let DecodingError.valueNotFound(_, value):
            context = value
        default:
            context = nil
        }

        if let underlyingError = context?.underlyingError {
            return description(of: underlyingError)
        }
        if let error = error as? LocalizedError, let description = error.errorDescription {
            return description
        }
        return context?.debugDescription ?? String(describing: error)
    }
}

public enum BazelizeConfigurationError: Error, LocalizedError {
    case fileAlreadyExists(String)
    case fileNotFound(String)
    case invalidFile(String, String)

    public var errorDescription: String? {
        switch self {
        case let .fileAlreadyExists(path):
            return "Configuration file already exists: \(path)"
        case let .fileNotFound(path):
            return "Configuration file not found: \(path)"
        case let .invalidFile(path, reason):
            return "Invalid configuration file at \(path): \(reason)"
        }
    }
}

private extension BazelizeConfiguration {
    struct Document: Decodable {
        let schema: Int
        let buildifier: BuildifierDocument

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: ConfigurationKey.self)
            try rejectUnknownKeys(in: container, allowed: ["schema", "buildifier"])

            schema = try container.decode(Int.self, forKey: ConfigurationKey("schema"))
            guard schema == 1 else { throw DocumentError.unsupportedSchema(schema) }
            buildifier = try container.decode(
                BuildifierDocument.self,
                forKey: ConfigurationKey("buildifier"))
        }
    }

    struct BuildifierDocument: Decodable {
        let version: String

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: ConfigurationKey.self)
            try rejectUnknownKeys(in: container, allowed: ["version"])
            version = try container.decode(String.self, forKey: ConfigurationKey("version"))
        }
    }

    static func rejectUnknownKeys(
        in container: KeyedDecodingContainer<ConfigurationKey>,
        allowed: Set<String>) throws {
        guard let key = container.allKeys
            .filter({ !allowed.contains($0.stringValue) })
            .sorted(by: { $0.stringValue < $1.stringValue })
            .first
        else { return }

        let path = (container.codingPath + [key])
            .map(\.stringValue)
            .joined(separator: ".")
        throw DocumentError.unknownProperty(path)
    }
}

private struct ConfigurationKey: CodingKey, Hashable {
    let stringValue: String
    let intValue: Int? = nil

    init(_ stringValue: String) {
        self.stringValue = stringValue
    }

    init?(stringValue: String) {
        self.init(stringValue)
    }

    init?(intValue _: Int) {
        return nil
    }
}

private enum DocumentError: Error, LocalizedError {
    case unknownProperty(String)
    case unsupportedSchema(Int)
    case unsupportedBuildifier(String)

    var errorDescription: String? {
        switch self {
        case let .unknownProperty(path):
            return "Unknown property '\(path)'."
        case let .unsupportedSchema(schema):
            return "Unsupported schema \(schema); expected 1."
        case let .unsupportedBuildifier(version):
            return "Unsupported buildifier version '\(version)'."
        }
    }
}
