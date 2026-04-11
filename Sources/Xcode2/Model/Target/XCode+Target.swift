public extension XCode {
    struct Target: Codable {
        public let name: String
        public let productName: String?
        public let productType: String?
        public let configs: [String: [String: JSONValue]]
        public let metadata: TargetMetadata
        public let buildPhases: [BuildPhase]
        public let files: Files
        public let dependencies: Dependencies
    }
}
