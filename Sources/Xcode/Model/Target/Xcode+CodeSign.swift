extension Xcode {
    public struct CodeSign: Codable {
        public let developmentTeam: String?
        public let codeSignStyle: String?
        public let codeSignIdentity: String?

        package init(developmentTeam: String?, codeSignStyle: String?, codeSignIdentity: String?) {
            self.developmentTeam = developmentTeam
            self.codeSignStyle = codeSignStyle
            self.codeSignIdentity = codeSignIdentity
        }
    }
}
