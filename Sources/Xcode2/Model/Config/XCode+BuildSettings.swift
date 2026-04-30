import Foundation
import XcodeProj

extension BuildSetting {
    var value: String {
        switch self {
        case .string(let value):
            return value
        case .array(let value):
            return value.joined(separator: " ")
        }
    }
}

// MARK: - XCode.BuildSettings

extension XCode {
    public struct BuildSettings: Encodable {
        public let name: String
        private let setting: [String: String]

        public init(name: String, setting: [String: String]) {
            self.name = name
            self.setting = setting
        }

        init(_ config: XCBuildConfiguration) {
            self.init(
                name: config.name,
                setting: config.buildSettings.mapValues(\.value))
        }

        func merged(with defaults: BuildSettings?) -> BuildSettings {
            guard let defaults else {
                return self
            }

            return .init(
                name: name,
                setting: setting.merging(defaults.setting) { current, _ in
                    current
                })
        }

        public subscript(key: String) -> String? {
            setting[key]
        }

        var keys: [String] {
            Array(setting.keys)
        }
    }
}

extension XCode.BuildSettings {
    public var swiftVersion: String? { self["SWIFT_VERSION"] }
    public var swiftDefine: String? { self["OTHER_SWIFT_FLAGS"] }
    public var testTargetName: String? { self["TEST_TARGET_NAME"] }
    public var testHost: String? { self["TEST_HOST"] }
    public var bundleLoader: String? { self["BUNDLE_LOADER"] }
    public var enableModules: Bool { self["CLANG_ENABLE_MODULES"] == "YES" }
}
