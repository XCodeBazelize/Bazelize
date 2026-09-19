extension BazelDep {
    /// https://github.com/bazelbuild/rules_shell
    enum RulesShell: String {
        static let latest: RulesShell = .v0_8_0

        case v0_8_0 = "0.8.0"
        case v0_7_1 = "0.7.1"
        case v0_6_1 = "0.6.1"
        case v0_6_0 = "0.6.0"
        case v0_5_1 = "0.5.1"
        case v0_5_0 = "0.5.0"
        case v0_4_1 = "0.4.1"
        case v0_4_0 = "0.4.0"
        case v0_3_0 = "0.3.0"
        case v0_2_0 = "0.2.0"
        case v0_1_0 = "0.1.0"
    }
}
