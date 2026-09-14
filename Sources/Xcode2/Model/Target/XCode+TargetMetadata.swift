extension XCode {
    public struct TargetMetadata: Codable {
        public let bundleID: String?
        public let moduleName: String?
        public let infoPlist: String?
        public let entitlements: String?
        public let deploymentTargets: [String: String]
        public let codeSign: CodeSign
    }
}
