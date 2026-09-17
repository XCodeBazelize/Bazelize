import Foundation
import PathKit

// MARK: - XCode.Project

extension XCode {
    public struct Project: Encodable {
        public let name: String
        public let workspacePath: String
        public let projectPath: String
        public let preferConfig: String?
        public let configs: [String: BuildSettings]
        public let packages: Packages
        public let targets: [Target]

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
                projectPath: manifest.string,
                preferConfig: nil,
                configs: [:],
                packages: .init(
                    remote: [],
                    local: [.init(name: root.lastComponent, relativePath: ".")]),
                targets: [])
        }
    }
}

extension XCode.Project {
    public var config: [String: XCode.BuildSettings]? {
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
            guard let content = try? String(contentsOfFile: manifest.string) else { continue }

            let directory = Path(package.relativePath).lastComponent
            for product in content.swiftPackageProductNames {
                result[product] = directory
            }
        }

        return result
    }

    public var localPackagePathByProduct: [String: String] {
        var result: [String: String] = [:]

        for target in targets {
            for product in target.dependencies.packageProducts {
                if let packagePath = product.packagePath {
                    result[product.productName] = packagePath
                }
            }
        }

        return result
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
