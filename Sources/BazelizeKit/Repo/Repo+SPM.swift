
extension Repo {
    /// https://github.com/cgrindel/rules_spm
    enum SPM: String {
        case v0_11_0 = "v0.11.0"
        case v0_10_0 = "v0.10.0"
        case v0_9_0 = "v0.9.0"
        case v0_8_0 = "v0.8.0"
        case v0_7_0 = "v0.7.0"
        case v0_6_0 = "v0.6.0"
        case v0_5_2 = "v0.5.2"
        case v0_5_1 = "v0.5.1"
        case v0_5_0 = "v0.5.0"
        case v0_4_0 = "v0.4.0"
        case v0_3_0_alpha = "v0.3.0-alpha"
        case v0_2_0_alpha = "v0.2.0-alpha"
        case v0_1_0_alpha = "v0.1.0-alpha"
        var sha256: String {
            return ""
        }
    }
}