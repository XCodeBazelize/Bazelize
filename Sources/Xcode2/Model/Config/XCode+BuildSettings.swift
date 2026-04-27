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

public extension XCode {
    struct BuildSettings: Encodable {
        public let name: String
        public let setting: [String: String]

        public init(name: String, setting: [String: String]) {
            self.name = name
            self.setting = setting
        }

        init(_ config: XCBuildConfiguration) {
            self.init(
                name: config.name,
                setting: config.buildSettings.mapValues(\.value)
            )
        }

        func merged(with defaults: BuildSettings?) -> BuildSettings {
            guard let defaults else {
                return self
            }

            return .init(
                name: name,
                setting: setting.merging(defaults.setting) { current, _ in
                    current
                }
            )
        }

        public subscript(key: String) -> String? {
            setting[key]
        }
    }
}
