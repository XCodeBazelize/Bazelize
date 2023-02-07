
extension Repo {
    /// https://github.com/bazelbuild/rules_swift
    enum Swift: String {
        case v1_5_1 = "1.5.1"
        case v1_5_0 = "1.5.0"
        case v1_4_0 = "1.4.0"
        case v1_3_0 = "1.3.0"
        case v1_2_0 = "1.2.0"
        // MARK: Internal

        var version: String {
            if rawValue.first == "v" {
                return String(rawValue.dropFirst())
            }
            return rawValue
        }

        var sha256: String {
            switch self {
            case .v1_5_1: return "84e2cc1c9e3593ae2c0aa4c773bceeb63c2d04c02a74a6e30c1961684d235593"
            case .v1_5_0: return "32f95dbe6a88eb298aaa790f05065434f32a662c65ec0a6aabdaf6881e4f169f"
            case .v1_4_0: return "c244e9f804a48c27fe490150c762d8b0c868b23ef93dc4e3f93d8117ca216d92"
            case .v1_3_0: return "2ce874c8c34a03a0a33bfb0c8100f0be32279e0a40f5b794fd943f15441e034a"
            case .v1_2_0: return "51efdaf85e04e51174de76ef563f255451d5a5cd24c61ad902feeadafc7046d9"
            }
        }
    }
}