
extension Repo {
    /// https://github.com/pinterest/PodToBUILD
    enum Pod: String {
        case v4_1_0_412495 = "4.1.0-412495"
        case v4_0_0_5787125 = "4.0.0-5787125"
        case v4_0_0_2096f5c = "4.0.0-2096f5c"
        case v4_0_0_7673f06 = "4.0.0-7673f06"
        case v4_0_0_f96b657 = "4.0.0-f96b657"

        // MARK: Internal

        var version: String {
            if rawValue.first == "v" {
                return String(rawValue.dropFirst())
            }
            return rawValue
        }

        var sha256: String {
            switch self {
            case .v4_1_0_412495: return "c96bbfb6364a76e09d8239914990328e66074096038728f1a1b26c62d9081af6"
            case .v4_0_0_5787125: return "d697642a6ca9d4d0441a5a6132e9f2bf70e8e9ee0080c3c780fe57e698e79d82"
            case .v4_0_0_2096f5c: return "27e168882f74adc33c901d4c930bddbdc38282185bedb8737290022891737f02"
            case .v4_0_0_7673f06: return "92eccc22950dcc86e86f4cbc3fb538b4b927da2cd765627ba099f30aa7dbf73b"
            case .v4_0_0_f96b657: return "1faf148ba6f0e494d5ccd730ae26130a5966161be034e775f76317897cf68aad"
            }
        }
    }
}