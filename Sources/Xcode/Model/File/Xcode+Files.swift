// MARK: - Xcode.Files

extension Xcode {
    public struct Files: Codable {
        public let sources: [File]
        public let headers: [File]
        public let resources: [File]
        public let frameworks: [File]
        public let copyFiles: [File]
        public let others: [File]
        /// Declared local inputs omitted from generated rules because they are
        /// absent. Kept separately so generation can still name each one.
        public var missing: [File] = []

        package init(
            sources: [File],
            headers: [File],
            resources: [File],
            frameworks: [File],
            copyFiles: [File],
            others: [File],
            missing: [File] = [])
        {
            self.sources = sources
            self.headers = headers
            self.resources = resources
            self.frameworks = frameworks
            self.copyFiles = copyFiles
            self.others = others
            self.missing = missing
        }
    }
}

extension Xcode.Files {
    enum CodingKeys: String, CodingKey {
        case sources
        case headers
        case resources
        case frameworks
        case copyFiles
        case others
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(sources.nonEmpty, forKey: .sources)
        try container.encodeIfPresent(headers.nonEmpty, forKey: .headers)
        try container.encodeIfPresent(resources.nonEmpty, forKey: .resources)
        try container.encodeIfPresent(frameworks.nonEmpty, forKey: .frameworks)
        try container.encodeIfPresent(copyFiles.nonEmpty, forKey: .copyFiles)
        try container.encodeIfPresent(others.nonEmpty, forKey: .others)
    }
}
