public enum ConfigurationCondition {
    public static var name: String {
        #if DEBUG_ONLY && RELEASE_ONLY
        #error("debug and release settings must be mutually exclusive")
        #elseif DEBUG_ONLY
        return "debug"
        #elseif RELEASE_ONLY
        return "release"
        #else
        #error("one build configuration must be selected")
        #endif
    }
}
