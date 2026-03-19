
extension Repo {
    /// https://github.com/bazelbuild/rules_apple
    enum Apple: String {
        case v4_5_1 = "4.5.1"
        case v4_5_0 = "4.5.0"
        case v4_4_0 = "4.4.0"
        case v4_3_3 = "4.3.3"
        case v4_3_2 = "4.3.2"
        // MARK: Internal

        var version: String {
            if rawValue.first == "v" {
                return String(rawValue.dropFirst())
            }
            return rawValue
        }

        var sha256: String {
            switch self {
            case .v4_5_1: return "0831b6b305e22e007c561f8e48f618244091c9b34ff7aa571de66ddb0de6fdbe"
            case .v4_5_0: return "34953c6c5666f2bd864a4a2a27599eb6630a42fde18ba57292fa0a7fcb3d851c"
            case .v4_4_0: return "c6d8d0361cd7e48067a2cb3bb6bb295182f8e44ee66905f3d578d5a96bcac18c"
            case .v4_3_3: return "fad623b4d0dbe7883fffc95a3275eaabfd13bd9336fca6788cb40bee96e5f131"
            case .v4_3_2: return "f2b4117fe17b0f1f8a3769e6d760d433fcbf97a8b6ff1797077ec106ccfbe2f2"
            }
        }
    }
}