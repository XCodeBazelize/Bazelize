// MARK: - XCode.BuildPhase

extension XCode {
    public struct BuildPhase: Codable {
        public let type: String
        public let name: String?
        public let files: [BuildPhaseFile]
        public let inputPaths: [String]
        public let outputPaths: [String]
        public let inputFileListPaths: [String]
        public let outputFileListPaths: [String]
        public let shellScript: String?
        public let destination: CopyFilesDestination?
    }
}

extension XCode.BuildPhase {
    enum CodingKeys: String, CodingKey {
        case type
        case name
        case files
        case inputPaths
        case outputPaths
        case inputFileListPaths
        case outputFileListPaths
        case shellScript
        case destination
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(files.nonEmpty, forKey: .files)
        try container.encodeIfPresent(inputPaths.nonEmpty, forKey: .inputPaths)
        try container.encodeIfPresent(outputPaths.nonEmpty, forKey: .outputPaths)
        try container.encodeIfPresent(inputFileListPaths.nonEmpty, forKey: .inputFileListPaths)
        try container.encodeIfPresent(outputFileListPaths.nonEmpty, forKey: .outputFileListPaths)
        try container.encodeIfPresent(shellScript, forKey: .shellScript)
        try container.encodeIfPresent(destination, forKey: .destination)
    }
}

extension Array {
    var nonEmpty: Self? {
        isEmpty ? nil : self
    }
}
