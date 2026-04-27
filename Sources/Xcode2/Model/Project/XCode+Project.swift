import PathKit

public extension XCode {
    struct Project: Encodable {
        public let name: String
        public let workspacePath: String
        public let projectPath: String
        public let preferConfig: String?
        public let configs: [String: BuildSettings]
        public let packages: Packages
        public let targets: [Target]

        public static func load(path: Path, preferConfig: String?) throws -> Self {
            try ProjectLoader(path: path, preferConfig: preferConfig).model()
        }
    }
}
