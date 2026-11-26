extension Xcode {
    public struct TargetMetadata: Codable {
        public let bundleID: String?
        public let moduleName: String?
        public let infoPlist: String?
        public let entitlements: String?
        public let deploymentTargets: [String: String]
        public let codeSign: CodeSign

        package init(
            bundleID: String?,
            moduleName: String?,
            infoPlist: String?,
            entitlements: String?,
            deploymentTargets: [String: String],
            codeSign: CodeSign)
        {
            self.bundleID = bundleID
            self.moduleName = moduleName
            self.infoPlist = infoPlist
            self.entitlements = entitlements
            self.deploymentTargets = deploymentTargets
            self.codeSign = codeSign
        }
    }
}
