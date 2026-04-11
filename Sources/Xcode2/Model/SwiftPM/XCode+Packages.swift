public extension XCode {
    struct Packages: Codable {
        public let remote: [RemotePackage]
        public let local: [LocalPackage]
    }
}
