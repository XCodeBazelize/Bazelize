
extension Repo {
    /// https://github.com/bazelbuild/rules_apple
    enum Apple: String {
        case v2_0_0 = "2.0.0"
        case v2_0_0_rc2 = "2.0.0-rc2"
        case v2_0_0_rc1 = "2.0.0-rc1"
        case v1_1_3 = "1.1.3"
        case v1_1_2 = "1.1.2"
        // MARK: Internal

        var version: String {
            if rawValue.first == "v" {
                return String(rawValue.dropFirst())
            }
            return rawValue
        }

        var sha256: String {
            switch self {
            case .v2_0_0: return "43737f28a578d8d8d7ab7df2fb80225a6b23b9af9655fcdc66ae38eb2abcf2ed"
            case .v2_0_0_rc2: return "44c803313904f94ea14f55269c9ffabd355f66c9dca98768b907aff61c97abc3"
            case .v2_0_0_rc1: return "bf48acc73e536d36b4942857647ac219512d4984aca6ae083a11fd3fd540faa0"
            case .v1_1_3: return "f94e6dddf74739ef5cb30f000e13a2a613f6ebfa5e63588305a71fce8a8a9911"
            case .v1_1_2: return "90e3b5e8ff942be134e64a83499974203ea64797fd620eddeb71b3a8e1bff681"
            }
        }
    }
}