extension Xcode {
    public struct LocalPackage: Codable {
        public let name: String?
        public let relativePath: String

        package init(name: String?, relativePath: String) {
            self.name = name
            self.relativePath = relativePath
        }
    }
}
