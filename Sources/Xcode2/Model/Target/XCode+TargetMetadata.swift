public extension XCode {
    struct TargetMetadata: Codable {
        public let bundleID: String?
        public let moduleName: String?
        public let infoPlist: String?
        public let deploymentTargets: [String: String]
        public let codeSign: CodeSign
    }
}
