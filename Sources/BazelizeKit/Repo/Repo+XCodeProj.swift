
extension Repo {
    /// https://github.com/buildbuddy-io/rules_xcodeproj
    enum XCodeProj: String {
        case v1_0_0rc1 = "1.0.0rc1"
        case v0_12_3 = "0.12.3"
        case v0_12_2 = "0.12.2"
        case v0_12_0 = "0.12.0"
        case v0_11_0 = "0.11.0"
        // MARK: Internal

        var version: String {
            if rawValue.first == "v" {
                return String(rawValue.dropFirst())
            }
            return rawValue
        }

        var sha256: String {
            switch self {
            case .v1_0_0rc1: return "0164d576945121361b28706a5bbe2ea6f834f93ae65062e5592544b728577d30"
            case .v0_12_3: return "f3f9b6db442892af4d16c2819d921ef8607ef86276ca8c762b82800f5d6755ad"
            case .v0_12_2: return "9c86784491854f205b075e5c4d8a838612d433d9454a226d270ad1a17ad8d634"
            case .v0_12_0: return "630e3434b49e80783430ef470c0e9a7f1c8b4e648f789b9fe324fcd37ade8a19"
            case .v0_11_0: return "2533b977ac8540a30323fde7fdb6ca49219edd21d3753b69d43f39c576b11a88"
            }
        }
    }
}