
extension Repo {
    /// https://github.com/bazelbuild/rules_apple
    enum Apple: String {
        case v1_1_2 = "1.1.2"
        case v1_1_1 = "1.1.1"
        case v1_1_0 = "1.1.0"
        case v1_0_1 = "1.0.1"
        case v1_0_0 = "1.0.0"

        // MARK: Internal

        var version: String {
            if rawValue.first == "v" {
                return String(rawValue.dropFirst())
            }
            return rawValue
        }

        var sha256: String {
            switch self {
            case .v1_1_2: return "90e3b5e8ff942be134e64a83499974203ea64797fd620eddeb71b3a8e1bff681"
            case .v1_1_1: return "a19cf84dd060eda50be9ba5b0eca88377e0306ffbc1cc059df6a6947e48ac61a"
            case .v1_1_0: return "f003875c248544009c8e8ae03906bbdacb970bc3e5931b40cd76cadeded99632"
            case .v1_0_1: return "36072d4f3614d309d6a703da0dfe48684ec4c65a89611aeb9590b45af7a3e592"
            case .v1_0_0: return "f5f4084830a7aac2b4c5fb4e9faa0f781fcf1d43e4282a015768e18f3daff603"
            }
        }
    }
}