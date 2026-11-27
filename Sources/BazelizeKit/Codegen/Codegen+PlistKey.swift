/// The `Info.plist` keys the generator writes, drops, or checks by name.
enum PlistKey: String {
    case bundleName = "CFBundleName"
    case bundleIdentifier = "CFBundleIdentifier"
    case bundleVersion = "CFBundleVersion"
    case bundleShortVersionString = "CFBundleShortVersionString"
    case bundleExecutable = "CFBundleExecutable"
    case bundleDevelopmentRegion = "CFBundleDevelopmentRegion"
    case bundlePackageType = "CFBundlePackageType"
    case bundleIconFile = "CFBundleIconFile"
    case bundleIconFiles = "CFBundleIconFiles"
    case bundleIconName = "CFBundleIconName"
}
