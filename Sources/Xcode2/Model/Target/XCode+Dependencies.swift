// MARK: - XCode.Dependencies

extension XCode {
    public struct Dependencies: Codable {
        public let targets: [String]
        public let packageProducts: [PackageProductDependency]
        public let frameworks: [String]
        public let sdkDylibs: [String]
        public let sdkFrameworks: [String]
        /// Directories holding the linked system frameworks, e.g.
        /// `/System/Library/PrivateFrameworks`, which the linker does not search by
        /// default.
        public let sdkFrameworkSearchPaths: [String]
        public let weakSDKFrameworks: [String]
    }
}

extension XCode.Dependencies {
    enum CodingKeys: String, CodingKey {
        case targets
        case packageProducts
        case frameworks
        case sdkDylibs
        case sdkFrameworks
        case sdkFrameworkSearchPaths
        case weakSDKFrameworks
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(targets.nonEmpty, forKey: .targets)
        try container.encodeIfPresent(packageProducts.nonEmpty, forKey: .packageProducts)
        try container.encodeIfPresent(frameworks.nonEmpty, forKey: .frameworks)
        try container.encodeIfPresent(sdkDylibs.nonEmpty, forKey: .sdkDylibs)
        try container.encodeIfPresent(sdkFrameworks.nonEmpty, forKey: .sdkFrameworks)
        try container.encodeIfPresent(sdkFrameworkSearchPaths.nonEmpty, forKey: .sdkFrameworkSearchPaths)
        try container.encodeIfPresent(weakSDKFrameworks.nonEmpty, forKey: .weakSDKFrameworks)
    }
}
