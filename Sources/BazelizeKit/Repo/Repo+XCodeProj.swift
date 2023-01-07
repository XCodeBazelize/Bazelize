
extension Repo {
    /// https://github.com/buildbuddy-io/rules_xcodeproj
    enum XCodeProj: String {
        case v0_11_0 = "0.11.0"
        case v0_10_2 = "0.10.2"
        case v0_10_1 = "0.10.1"
        case v0_10_0 = "0.10.0"
        case v0_9_0 = "0.9.0"

        // MARK: Internal

        var version: String {
            if rawValue.first == "v" {
                return String(rawValue.dropFirst())
            }
            return rawValue
        }

        var sha256: String {
            switch self {
            case .v0_11_0: return "2533b977ac8540a30323fde7fdb6ca49219edd21d3753b69d43f39c576b11a88"
            case .v0_10_2: return "b4e71c7740bb8cfa4bc0b91c0f18ac512debcc111ebe471280e24f579a3b0782"
            case .v0_10_1: return "598449ff3a08972227363a55d22b54707468ecf4370ff56662f9d6026f72c7a7"
            case .v0_10_0: return "2f9638b7bae45c0ba6f53a66788a0ec17db6455f4db4df6abaf07017ee9a9419"
            case .v0_9_0: return "564381b33261ba29e3c8f505de82fc398452700b605d785ce3e4b9dd6c73b623"
            }
        }
    }
}