extension BazelDep {
    /// https://github.com/bazelbuild/platforms
    enum Platforms: String {
        static let latest: Platforms = .v1_1_0

        case v1_1_0 = "1.1.0"
        case v1_0_0 = "1.0.0"
        case v0_0_11 = "0.0.11"
        case v0_0_10 = "0.0.10"
        case v0_0_9 = "0.0.9"
        case v0_0_8 = "0.0.8"
        case v0_0_7 = "0.0.7"
        case v0_0_6 = "0.0.6"
        case v0_0_5 = "0.0.5"
        case v0_0_4 = "0.0.4"
    }
}
