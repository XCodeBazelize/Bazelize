public extension XCode {
    struct RemotePackage: Codable {
        public let name: String?
        public let repositoryURL: String?
        public let requirement: String?
    }
}
