public extension XCode {
    struct BuildPhaseFile: Codable {
        public let name: String?
        public let path: String?
        public let fileType: String?
        public let compilerFlags: String?
        public let attributes: [String]
    }
}
