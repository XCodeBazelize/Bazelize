extension Xcode {
    public struct Packages: Codable {
        public let remote: [RemotePackage]
        public let local: [LocalPackage]

        package init(remote: [RemotePackage], local: [LocalPackage]) {
            self.remote = remote
            self.local = local
        }
    }
}
