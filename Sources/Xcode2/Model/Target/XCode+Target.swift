public extension XCode {
    struct Target: Encodable {
        public let name: String
        public let productName: String?
        public let productType: String?
        public let configs: [String: BuildSettings]
        public let metadata: TargetMetadata
        public let buildPhases: [BuildPhase]
        public let files: Files
        public let dependencies: Dependencies
    }
}
