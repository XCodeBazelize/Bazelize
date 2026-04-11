public extension XCode {
    struct BuildPhase: Codable {
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
