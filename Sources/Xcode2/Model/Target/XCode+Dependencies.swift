public extension XCode {
    struct Dependencies: Codable {
        public let targets: [String]
        public let packageProducts: [PackageProductDependency]
        public let frameworks: [String]
        public let sdkFrameworks: [String]
    }
}
