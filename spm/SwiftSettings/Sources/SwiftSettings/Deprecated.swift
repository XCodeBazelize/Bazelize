/// A deprecation the target uses on purpose.
///
/// `treatAllWarnings(as: .error)` would make this an error; `treatWarning(
/// "DeprecatedDeclaration", as: .warning)` puts it back to a warning. A build
/// that drops the second setting fails here, which is the point: the setting is
/// only observable when something trips it.
@available(*, deprecated, message: "deprecated so the warning settings are observable")
func deprecatedProbe() -> Int {
    1
}

public enum WarningSettings {
    public static var deprecatedProbeValue: Int {
        deprecatedProbe()
    }
}
