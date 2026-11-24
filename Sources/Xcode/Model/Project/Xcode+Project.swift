import BasicContainers
import Foundation
import PathKit

// MARK: - Xcode.Project

extension Xcode {
    /// The loaded project, and the sole owner of its targets.
    public struct Project: ~Copyable {
        public let name: String
        public let workspacePath: String
        public let projectPath: String
        public let preferConfig: String?
        public let configs: [String: BuildSettings]
        public let packages: Packages
        /// Targets in the project's declaration order. Read them in place
        /// through the subscript or `forEachTarget`; a target is never copied.
        public let targets: UniqueArray<Target>

        public static func load(path: Path, preferConfig: String?) throws -> Self {
            if let manifest = Self.manifest(at: path) {
                return package(at: manifest)
            }

            return try ProjectLoader(path: path, preferConfig: preferConfig).model()
        }

        /// The `Package.swift` a path names, directly or as its directory.
        static func manifest(at path: Path) -> Path? {
            if path.lastComponent == "Package.swift", path.exists { return path }

            let manifest = path + "Package.swift"
            return manifest.exists ? manifest : nil
        }

        /// A Swift package on its own, described as a project with no targets of its
        /// own.
        ///
        /// Everything a package needs is already generated for a package a project
        /// depends on: the rules live under `Packages/`, reached by product labels.
        /// A package given directly is the same thing — the one local package of a
        /// project that has nothing else in it — so nothing else has to know the
        /// input was a manifest.
        private static func package(at manifest: Path) -> Self {
            let root = manifest.parent().absolute()

            return .init(
                name: root.lastComponent,
                workspacePath: root.string,
                projectPath: (root + manifest.lastComponent).string,
                preferConfig: nil,
                configs: [:],
                packages: .init(
                    remote: [],
                    local: [.init(name: root.lastComponent, relativePath: ".")]),
                targets: .init())
        }
    }
}

extension Xcode.Project {
    /// The package that was handed to bazelize, when the input was a manifest
    /// rather than an `.xcodeproj`.
    public var packageRoot: Path? {
        let path = Path(projectPath)
        guard path.lastComponent == "Package.swift" else { return nil }
        return path.parent()
    }

    public var config: [String: Xcode.BuildSettings]? {
        configs
    }

    public var workspaceRoot: Path {
        Path(workspacePath)
    }

    /// The directory of the local package that declares a product, for the
    /// products Xcode references without naming their package.
    public var localPackageDirectoryByProduct: [String: String] {
        var result: [String: String] = [:]

        for package in packages.local {
            let packagePath = workspaceRoot + package.relativePath
            let manifest = packagePath + "Package.swift"
            guard let content = try? String(contentsOfFile: manifest.string, encoding: .utf8) else { continue }

            let directory = Path(package.relativePath).lastComponent
            for product in content.swiftPackageProductNames {
                result[product] = directory
            }
        }

        return result
    }

    public var localPackagePathByProduct: [String: String] {
        var result: [String: String] = [:]

        forEachTarget { target in
            for product in target.dependencies.packageProducts {
                if let packagePath = product.packagePath {
                    result[product.productName] = packagePath
                }
            }
        }

        return result
    }
}

// MARK: - Borrowing access

extension Xcode.Project {
    public var targetNames: [String] {
        mapTargets { $0.name }
    }

    public func forEachTarget<E: Error>(_ body: (borrowing Xcode.Target) throws(E) -> Void) throws(E) {
        for index in targets.indices {
            try body(targets[index])
        }
    }

    public func mapTargets<T, E: Error>(_ transform: (borrowing Xcode.Target) throws(E) -> T) throws(E) -> [T] {
        var result: [T] = []
        result.reserveCapacity(targets.count)
        for index in targets.indices {
            try result.append(transform(targets[index]))
        }
        return result
    }

    /// The position of the first target with this name.
    public func targetIndex(named name: String) -> Int? {
        targets.indices.first { targets[$0].name == name }
    }

    /// Lends the first target with this name to `body`.
    public func withTarget<R, E: Error>(
        named name: String,
        _ body: (borrowing Xcode.Target) throws(E) -> R) throws(E)
        -> R?
    {
        guard let index = targetIndex(named: name) else { return nil }
        return try body(targets[index])
    }
}

// MARK: - Encoding

extension Xcode.Project {
    enum CodingKeys: String, CodingKey {
        case name
        case workspacePath
        case projectPath
        case preferConfig
        case configs
        case packages
        case targets
    }

    /// Encodes the project as `Encodable` synthesis did, borrowing every target.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(workspacePath, forKey: .workspacePath)
        try container.encode(projectPath, forKey: .projectPath)
        try container.encodeIfPresent(preferConfig, forKey: .preferConfig)
        try container.encode(configs, forKey: .configs)
        try container.encode(packages, forKey: .packages)
        var targetContainer = container.nestedUnkeyedContainer(forKey: .targets)
        for index in targets.indices {
            try targets[index].encode(to: targetContainer.superEncoder())
        }
    }

    /// The project as JSON. A noncopyable value cannot conform to `Encodable`,
    /// so the encoder is handed a value that borrows the project for the
    /// duration of the call.
    public func jsonData(using encoder: JSONEncoder) throws -> Data {
        try BorrowedEncoding.encode(using: encoder) { try encode(to: $0) }
    }
}

// MARK: - BorrowedEncoding

/// An `Encodable` that runs a non-escaping encoding body, only for as long as
/// the `JSONEncoder` call that receives it.
private struct BorrowedEncoding: Encodable {
    let body: (any Encoder) throws -> Void

    static func encode(using encoder: JSONEncoder, _ body: (any Encoder) throws -> Void) throws -> Data {
        try withoutActuallyEscaping(body) { body in
            try encoder.encode(BorrowedEncoding(body: body))
        }
    }

    func encode(to encoder: any Encoder) throws {
        try body(encoder)
    }
}

extension String {
    fileprivate var swiftPackageProductNames: [String] {
        let pattern = #"\.library\s*\(\s*name:\s*"([^"]+)""#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(startIndex..., in: self)
        return regex.matches(in: self, range: range).compactMap { match in
            guard let capture = Range(match.range(at: 1), in: self) else { return nil }
            return String(self[capture])
        }
    }
}
