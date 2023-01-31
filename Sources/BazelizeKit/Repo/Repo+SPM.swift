
extension Repo {
    /// https://github.com/cgrindel/rules_spm
    enum SPM: String {
        case v0_11_2 = "v0.11.2"
        case v0_11_1 = "v0.11.1"
        case v0_11_0 = "v0.11.0"
        case v0_10_0 = "v0.10.0"
        case v0_9_0 = "v0.9.0"
        // MARK: Internal

        var version: String {
            if rawValue.first == "v" {
                return String(rawValue.dropFirst())
            }
            return rawValue
        }

        var sha256: String {
            switch self {
            case .v0_11_2: return "777e687245faa7340488e61f5abb23b95b4c0e27e05f7cea7318c03e4cc38289"
            case .v0_11_1: return "d36697e83720e4dc29a97c7a8f1a02858b3c6ce51fa645be3faa03f51dbc1151"
            case .v0_11_0: return "03718eb865a100ba4449ebcbca6d97bf6ea78fa17346ce6d55532312e8bf9aa8"
            case .v0_10_0: return "ba4310ba33cd1864a95e41d1ceceaa057e56ebbe311f74105774d526d68e2a0d"
            case .v0_9_0: return "b85d8d089c5f707b451f142718b32c647b22d0a72a5b7c1832af0f3e4d25be4f"
            }
        }
    }
}