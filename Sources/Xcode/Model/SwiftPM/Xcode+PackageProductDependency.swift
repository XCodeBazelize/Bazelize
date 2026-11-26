extension Xcode {
    public struct PackageProductDependency: Codable {
        public let productName: String
        public let package: String?
        public let packagePath: String?

        package init(productName: String, package: String?, packagePath: String?) {
            self.productName = productName
            self.package = package
            self.packagePath = packagePath
        }
    }
}
