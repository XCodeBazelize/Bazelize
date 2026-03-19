extension Repo {
    /// http://github.com/cgrindel/rules_swift_package_manager
    enum SPM: String {
        case v1_13_0 = "1.13.0"
        
        // MARK: Internal

        var version: String {
            if rawValue.first == "v" {
                return String(rawValue.dropFirst())
            }
            return rawValue
        }

        var sha256: String {
            return ""
        }
    }
}
