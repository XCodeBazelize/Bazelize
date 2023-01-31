
extension Repo {
    /// https://github.com/pinterest/xchammer
    enum Hammer: String {
        case v3_4_3_3 = "v3.4.3.3"
        case v3_4_3_2 = "v3.4.3.2"
        case v3_4_3_1 = "v3.4.3.1"
        case v3_4_2_2 = "v3.4.2.2"
        // MARK: Internal

        var version: String {
            if rawValue.first == "v" {
                return String(rawValue.dropFirst())
            }
            return rawValue
        }

        var sha256: String {
            switch self {
            case .v3_4_3_3: return "1fe8c3a283f3cfc3c7a3765e185103949bfa889c0e806897ac7ac247582d9a80"
            case .v3_4_3_2: return "cddf5fd1d0b6015a03a0b6eacd675093c9e0175c25357ab35de2e9a928d60fa5"
            case .v3_4_3_1: return "725d55d3f62e82c14544d479877862a4c2b1d4d7e903b38feb239c5a65aaa4c9"
            case .v3_4_2_2: return "20892993972a0a1b8dae305eb4f822d6374848a5e5631a811b88d73a0faa038a"
            }
        }
    }
}