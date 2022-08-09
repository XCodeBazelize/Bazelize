
extension Repo {
    /// https://github.com/pinterest/xchammer
    enum Hammer: String {
        case v3_4_3_3 = "v3.4.3.3"
        case v3_4_3_2 = "v3.4.3.2"
        case v3_4_3_1 = "v3.4.3.1"
        case v3_4_2_2 = "v3.4.2.2"

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