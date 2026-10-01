extension BazelDep {
    /// https://github.com/bazel-contrib/buildtools
    enum Buildifier: String {
        static let latest: Buildifier = .v10_1_0

        case v10_1_0 = "10.1.0"
        case v10_0_1 = "10.0.1"
        case v8_5_1 = "8.5.1"
        case v8_2_1 = "8.2.1"

        /// A host as `uname` names it, and the asset built for it.
        enum Host: String, CaseIterable {
            case darwin_arm64 = "buildifier-darwin-arm64"
            case darwin_x86_64 = "buildifier-darwin-amd64"
            case linux_aarch64 = "buildifier-linux-arm64"
            case linux_x86_64 = "buildifier-linux-amd64"

            /// `uname -s`, lowercased.
            var os: String {
                switch self {
                case .darwin_arm64:
                    return "darwin"
                case .darwin_x86_64:
                    return "darwin"
                case .linux_aarch64:
                    return "linux"
                case .linux_x86_64:
                    return "linux"
                }
            }

            /// `uname -m`.
            var machine: String {
                switch self {
                case .darwin_arm64:
                    return "arm64"
                case .darwin_x86_64:
                    return "x86_64"
                case .linux_aarch64:
                    return "aarch64"
                case .linux_x86_64:
                    return "x86_64"
                }
            }
        }

        func sha256(_ host: Host) -> String {
            switch self {
            case .v10_1_0:
                switch host {
                case .darwin_arm64:
                    return "e9804864c407f920f5ecbf03a5e056a8145e11a6ae6b90d2438a3fd106d34473"
                case .darwin_x86_64:
                    return "e9e10ff52ec8786fcabccd251c8109ebf31ef7be1f667e27c6e069b96dbdc1f6"
                case .linux_aarch64:
                    return "38d2ed845f560b4a16ddee41de906508a95f8dc85b04e0851b0a71e3a70d3890"
                case .linux_x86_64:
                    return "31b6a8aa1e5c746696788f428729701770ad91925873d8256cb885c60e12c77e"
                }
            case .v10_0_1:
                switch host {
                case .darwin_arm64:
                    return "afb78f350319b59cc51d6add3a5f3ba68e63e5d88f68c5a9ea6328a07084d319"
                case .darwin_x86_64:
                    return "1d02bb9148cadf2cbee330f9bd657352c765b52b68a03d970e10e47706bdc436"
                case .linux_aarch64:
                    return "6d7aebd23aa85847a66d517bb6220d95f24a2752e62cce0f089145b680b539c7"
                case .linux_x86_64:
                    return "e0ea28e2d639347724435ebafe0531fd764fbf20eec6a23000c81edd0d58e51d"
                }
            case .v8_5_1:
                switch host {
                case .darwin_arm64:
                    return "62836a9667fa0db309b0d91e840f0a3f2813a9c8ea3e44b9cd58187c90bc88ba"
                case .darwin_x86_64:
                    return "31de189e1a3fe53aa9e8c8f74a0309c325274ad19793393919e1ca65163ca1a4"
                case .linux_aarch64:
                    return "947bf6700d708026b2057b09bea09abbc3cafc15d9ecea35bb3885c4b09ccd04"
                case .linux_x86_64:
                    return "887377fc64d23a850f4d18a077b5db05b19913f4b99b270d193f3c7334b5a9a7"
                }
            case .v8_2_1:
                switch host {
                case .darwin_arm64:
                    return "cfab310ae22379e69a3b1810b433c4cd2fc2c8f4a324586dfe4cc199943b8d5a"
                case .darwin_x86_64:
                    return "9f8cffceb82f4e6722a32a021cbc9a5344b386b77b9f79ee095c61d087aaea06"
                case .linux_aarch64:
                    return "3baa1cf7eb41d51f462fdd1fff3a6a4d81d757275d05b2dd5f48671284e9a1a5"
                case .linux_x86_64:
                    return "6ceb7b0ab7cf66fceccc56a027d21d9cc557a7f34af37d2101edb56b92fcfa1a"
                }
            }
        }
    }
}
