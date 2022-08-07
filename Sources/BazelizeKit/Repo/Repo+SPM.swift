
extension Repo {
    /// https://github.com/cgrindel/rules_spm
    enum SPM: String {
        case v0_11_0 = "v0.11.0"
        case v0_10_0 = "v0.10.0"
        case v0_9_0 = "v0.9.0"
        case v0_8_0 = "v0.8.0"
        case v0_7_0 = "v0.7.0"

        var version: String {
            if rawValue.first == "v" {
                return String(rawValue.dropFirst())
            }
            return rawValue
        }

        var sha256: String {
            ""
        }
    }
}