//
//  Commands+Xcodebuild.swift
//
//  SDK and version queries for the selected Xcode.
//

import Foundation

extension Commands.xcodebuild {
    /// The JSON `xcodebuild -showsdks -json` prints for the installed SDKs.
    public static func installedSDKs() async throws -> Data {
        Data(try await Commands.text("/usr/bin/xcodebuild", ["-showsdks", "-json"]).utf8)
    }

    public static func xcodeVersion() async throws -> String {
        try await Commands.text("/usr/bin/xcodebuild", ["-version"])
    }
}
