
extension Repo {
    /// https://github.com/buildbuddy-io/rules_xcodeproj
    enum XCodeProj: String {
        case v3_6_0 = "3.6.0"
        case v3_5_1 = "3.5.1"
        case v3_4_1 = "3.4.1"
        case v3_4_0 = "3.4.0"
        case v3_3_0 = "3.3.0"
        // MARK: Internal

        var version: String {
            if rawValue.first == "v" {
                return String(rawValue.dropFirst())
            }
            return rawValue
        }

        var sha256: String {
            switch self {
            case .v3_6_0: return "207fc87aa2573c9c942d247c1db2416d6feaefd2e5c730ec1d7e640018fb4ca0"
            case .v3_5_1: return "dc3872fb50d16bbe7df035ea22eac4f79d0957036e226d6df9de5de389434393"
            case .v3_4_1: return "b25cb08c7c6f0c813984ed029f97b40357453d359b5fe494170dbaf46cc9c7db"
            case .v3_4_0: return "34473ab1756b357393ac45737718147a8a9b4a5607664bcc1b57fc203ffbf249"
            case .v3_3_0: return "78e17fd58175334abf1cdec46caa09b60da9e6cf3a07d51a9ee540f1ba712799"
            }
        }
    }
}