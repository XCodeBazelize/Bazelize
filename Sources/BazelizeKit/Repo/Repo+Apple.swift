
extension Repo {
    /// https://github.com/bazelbuild/rules_apple
    enum Apple: String {
        case v1_1_0 = "1.1.0"
        case v1_0_1 = "1.0.1"
        case v1_0_0 = "1.0.0"
        case v0_34_2 = "0.34.2"
        case v0_34_0 = "0.34.0"

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