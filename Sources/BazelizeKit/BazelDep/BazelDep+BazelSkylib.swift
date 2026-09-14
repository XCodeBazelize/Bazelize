extension BazelDep {
    /// https://github.com/bazelbuild/bazel-skylib
    enum BazelSkylib: String {
        static let latest: BazelSkylib = .v1_9_2

        case v1_9_2 = "1.9.2"
        case v1_9_0 = "1.9.0"
        case v1_8_2 = "1.8.2"
        case v1_8_1 = "1.8.1"
        case v1_8_0 = "1.8.0"
        case v1_7_1 = "1.7.1"
        case v1_7_0 = "1.7.0"
        case v1_6_1 = "1.6.1"
        case v1_6_0 = "1.6.0"
        case v1_5_0 = "1.5.0"
        case v1_4_2 = "1.4.2"
        case v1_4_1 = "1.4.1"
        case v1_4_0 = "1.4.0"
        case v1_3_0 = "1.3.0"
        case v1_2_1 = "1.2.1"
        case v1_2_0 = "1.2.0"
        case v1_1_1 = "1.1.1"
        case v1_0_3 = "1.0.3"
    }
}