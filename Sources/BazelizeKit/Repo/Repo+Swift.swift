
extension Repo {
    /// https://github.com/bazelbuild/rules_swift
    enum Swift: String {
        case v3_5_0 = "3.5.0"
        case v3_4_2 = "3.4.2"
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
            case .v3_5_0: return "c98f201bc217d2ce28e01afc78b410d05c67b846c04a7095e4e701b37422ecb2"
            case .v3_4_2: return "03a5c2a93398f2fc4d6ddfb76cf80cd957483ec286d34f50cc22cda002aab445"
            case .v3_4_1: return "6309d226474c6b9293f790d3da43d3b04dc0a71b75b87df3107871a0ea59d5f6"
            case .v3_4_0: return "13219bde174594c7af5403c7f3f41c37d1a62041294a0fd14c0834ca472fa8dc"
            case .v3_3_0: return "94136edf1ccdc7b9bb68ff85e006fe698ea161a02fbee55ba1feb4ce71522cfb"
            }
        }
    }
}