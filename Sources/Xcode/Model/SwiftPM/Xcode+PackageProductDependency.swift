extension Xcode {
    public struct PackageProductDependency: Codable {
        public let productName: String
        public let package: String?
        public let packagePath: String?
    }
}
