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

        func with(overrides: [String: String]) -> BuildSettings {
            .init(
                name: name,
                setting: setting.merging(overrides) { _, new in
                    new
                })
        }

        public subscript(key: String) -> String? {
            resolved(setting[key], visited: [key])
        }

        var keys: [String] {
            Array(setting.keys)
        }
    }
}

extension XCode.BuildSettings {
    public var swiftVersion: String? { self["SWIFT_VERSION"] }
    public var swiftDefine: String? { self["OTHER_SWIFT_FLAGS"] }
    public var bridgingHeader: String? { self["SWIFT_OBJC_BRIDGING_HEADER"] }

    /// `HEADER_SEARCH_PATHS` plus `USER_HEADER_SEARCH_PATHS`, without Xcode's
    /// `$(inherited)` marker.
    public var headerSearchPaths: [String] {
        ["HEADER_SEARCH_PATHS", "USER_HEADER_SEARCH_PATHS"]
            .compactMap { self[$0] }
            .flatMap { value in
                value.split(separator: " ").map(String.init)
            }
            .map { path in
                path.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            }
            .filter { path in
                !path.isEmpty && path != "$(inherited)"
            }
    }

    public var testTargetName: String? { self["TEST_TARGET_NAME"] }
    public var testHost: String? { self["TEST_HOST"] }
    public var bundleLoader: String? { self["BUNDLE_LOADER"] }
    public var enableModules: Bool { self["CLANG_ENABLE_MODULES"] == "YES" }
}

extension XCode.BuildSettings {
    private func resolved(_ value: String?, visited: Set<String>) -> String? {
        guard let value else { return nil }

        let pattern = #"\$\(([A-Za-z0-9_]+)\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return value }

        let matches = regex.matches(
            in: value,
            range: NSRange(value.startIndex..., in: value))
        guard !matches.isEmpty else { return value }

        var result = value
        for match in matches.reversed() {
            guard
                match.numberOfRanges == 2,
                let wholeRange = Range(match.range(at: 0), in: value),
                let keyRange = Range(match.range(at: 1), in: value)
            else {
                continue
            }

            let key = String(value[keyRange])
            guard !visited.contains(key), let replacement = resolved(setting[key], visited: visited.union([key])) else {
                continue
            }

            result.replaceSubrange(wholeRange, with: replacement)
        }

        return result
    }
}
