public extension XCode {
    struct CodeSign: Codable {
        public let developmentTeam: String?
        public let codeSignStyle: String?
        public let codeSignIdentity: String?
    }
}
