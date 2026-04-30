// MARK: - XCode.Files

extension XCode {
    public struct Files: Codable {
        public let sources: [File]
        public let headers: [File]
        public let resources: [File]
        public let frameworks: [File]
        public let copyFiles: [File]
        public let others: [File]
    }
}

extension XCode.Files {
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
