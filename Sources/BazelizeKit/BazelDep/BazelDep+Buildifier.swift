extension BazelDep {
    /// https://github.com/bazel-contrib/buildtools
    enum Buildifier: String {
        static let latest: Buildifier = .v10_1_0

        case v10_1_0 = "10.1.0"
        case v10_0_1 = "10.0.1"
        case v8_5_1 = "8.5.1"
        case v8_2_1 = "8.2.1"

        var darwinARM64SHA256: String {
            switch self {
            case .v10_1_0:
                return "e9804864c407f920f5ecbf03a5e056a8145e11a6ae6b90d2438a3fd106d34473"
            case .v10_0_1:
                return "afb78f350319b59cc51d6add3a5f3ba68e63e5d88f68c5a9ea6328a07084d319"
            case .v8_5_1:
                return "62836a9667fa0db309b0d91e840f0a3f2813a9c8ea3e44b9cd58187c90bc88ba"
            case .v8_2_1:
                return "cfab310ae22379e69a3b1810b433c4cd2fc2c8f4a324586dfe4cc199943b8d5a"
            }
        }

        var darwinAMD64SHA256: String {
            switch self {
            case .v10_1_0:
                return "e9e10ff52ec8786fcabccd251c8109ebf31ef7be1f667e27c6e069b96dbdc1f6"
            case .v10_0_1:
                return "1d02bb9148cadf2cbee330f9bd657352c765b52b68a03d970e10e47706bdc436"
            case .v8_5_1:
                return "31de189e1a3fe53aa9e8c8f74a0309c325274ad19793393919e1ca65163ca1a4"
            case .v8_2_1:
                return "9f8cffceb82f4e6722a32a021cbc9a5344b386b77b9f79ee095c61d087aaea06"
            }
        }
    }
}