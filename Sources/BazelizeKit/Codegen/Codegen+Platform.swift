import XCode2

extension Target {
    /// The platform the target builds for.
    ///
    /// `SDKROOT` is optional in a project file — Xcode falls back to the platform
    /// implied by the deployment target — so the rule choice cannot depend on the
    /// setting being present.
    var platformSDK: SDK? {
        prefer(\.platform.resolvedSDK)
    }

    /// The device families a bundle rule is built for.
    ///
    /// `TARGETED_DEVICE_FAMILY` is optional in a project file: Xcode then builds
    /// for every family the platform has, and an iOS bundle rule requires the
    /// attribute, so the default has to be stated.
    var deviceFamilies: [String]? {
        if let declared = prefer(\.platform.deviceFamily), !declared.isEmpty {
            return declared.map(\.code)
        }

        return platformSDK == .iOS ? [XCode.DeviceFamily.iphone.code, XCode.DeviceFamily.ipad.code] : nil
    }
}
