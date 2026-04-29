public extension XCode {
    struct Dependencies: Codable {
        public let targets: [String]
        public let packageProducts: [PackageProductDependency]
        public let frameworks: [String]
        public let sdkFrameworks: [String]
    }
}

extension XCode.Dependencies {
    enum CodingKeys: String, CodingKey {
        case targets
        case packageProducts
        case frameworks
        case sdkFrameworks
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(targets.nonEmpty, forKey: .targets)
        try container.encodeIfPresent(packageProducts.nonEmpty, forKey: .packageProducts)
        try container.encodeIfPresent(frameworks.nonEmpty, forKey: .frameworks)
        try container.encodeIfPresent(sdkFrameworks.nonEmpty, forKey: .sdkFrameworks)
    }
}
