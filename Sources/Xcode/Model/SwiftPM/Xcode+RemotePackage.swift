extension Xcode {
    public struct RemotePackage: Codable {
        public enum Requirement: Codable, Equatable {
            case upToNextMajorVersion(String)
            case upToNextMinorVersion(String)
            case range(from: String, to: String)
            case exact(String)
            case branch(String)
            case revision(String)
        }

        public let name: String?
        public let repositoryURL: String?
        public let version: Requirement?
    }
}
