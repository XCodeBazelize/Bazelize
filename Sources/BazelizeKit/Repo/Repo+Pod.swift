
extension Repo {
    /// https://github.com/pinterest/PodToBUILD
    enum Pod: String {
        case v4_1_0_412495 = "4.1.0-412495"
        case v4_0_0_5787125 = "4.0.0-5787125"
        case v4_0_0_2096f5c = "4.0.0-2096f5c"
        case v4_0_0_7673f06 = "4.0.0-7673f06"
        case v4_0_0_f96b657 = "4.0.0-f96b657"

        var version: String {
            if self.rawValue.first == "v" {
                return String(self.rawValue.dropFirst())
            }
            return self.rawValue
        }

        var sha256: String {
            return ""
        }
    }
}