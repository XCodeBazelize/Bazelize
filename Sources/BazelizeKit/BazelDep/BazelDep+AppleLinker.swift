extension BazelDep {
    /// https://github.com/keith/rules_apple_linker
    enum AppleLinker: String {
        static let latest: AppleLinker = .v0_7_0

        case v0_7_0 = "0.7.0"
        case v0_6_3 = "0.6.3"
        case v0_6_2 = "0.6.2"
        case v0_5_4 = "0.5.4"
        case v0_5_3 = "0.5.3"
        case v0_5_2 = "0.5.2"
        case v0_5_1 = "0.5.1"
        case v0_5_0 = "0.5.0"
        case v0_4_0 = "0.4.0"
        case v0_3_1 = "0.3.1"
        case v0_3_0 = "0.3.0"
    }
}