public extension XCode {
    struct File: Codable {
        public let name: String?
        public let path: String?
        public let fullPath: String?
        public let label: String?
        public let fileType: String?
        public let sourceTree: String
        public let buildPhase: String?
        public let compilerFlags: String?
        public let attributes: [String]
    }
}
