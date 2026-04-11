public extension XCode {
    struct Files: Codable {
        public let sources: [File]
        public let headers: [File]
        public let resources: [File]
        public let frameworks: [File]
        public let copyFiles: [File]
        public let others: [File]
    }
}
