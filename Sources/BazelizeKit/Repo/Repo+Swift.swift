
extension Repo {
    /// https://github.com/bazelbuild/rules_swift
    enum Swift: String {
        case v1_5_0 = "1.5.0"
        case v1_4_0 = "1.4.0"
        case v1_3_0 = "1.3.0"
        case v1_2_0 = "1.2.0"
        case v1_1_1 = "1.1.1"

        // MARK: Internal

        var version: String {
            if rawValue.first == "v" {
                return String(rawValue.dropFirst())
            }
            return rawValue
        }

        var sha256: String {
            switch self {
            case .v1_5_0: return "32f95dbe6a88eb298aaa790f05065434f32a662c65ec0a6aabdaf6881e4f169f"
            case .v1_4_0: return "c244e9f804a48c27fe490150c762d8b0c868b23ef93dc4e3f93d8117ca216d92"
            case .v1_3_0: return "2ce874c8c34a03a0a33bfb0c8100f0be32279e0a40f5b794fd943f15441e034a"
            case .v1_2_0: return "51efdaf85e04e51174de76ef563f255451d5a5cd24c61ad902feeadafc7046d9"
            case .v1_1_1: return "043897b483781cfd6cbd521569bfee339c8fbb2ad0f0bdcd1b3749523a262cf4"
            }
        }
    }
}