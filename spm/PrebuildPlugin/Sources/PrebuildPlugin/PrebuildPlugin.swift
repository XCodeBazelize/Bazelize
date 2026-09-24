/// `prebuilt` is not here: the plugin's prebuild command writes it, and this
/// only passes it on.
public func prebuiltValue() -> String {
    prebuilt
}
