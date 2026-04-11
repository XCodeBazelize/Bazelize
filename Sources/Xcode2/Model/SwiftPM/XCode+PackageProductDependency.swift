public extension XCode {
    struct PackageProductDependency: Codable {
        public let productName: String
        public let package: String?
    }
}
