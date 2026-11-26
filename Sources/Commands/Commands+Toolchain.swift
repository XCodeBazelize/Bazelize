//
//  Commands+Toolchain.swift
//
//  Queries of the selected Xcode, its SDKs, and the binaries built with them.
//

import Foundation
@preconcurrency import PathKit

extension Commands {
    /// The JSON `xcodebuild -showsdks -json` prints for the installed SDKs.
    public static func installedSDKs() async throws -> Data {
        Data(try await text("/usr/bin/xcodebuild", ["-showsdks", "-json"]).utf8)
    }

    public static func xcodeVersion() async throws -> String {
        try await text("/usr/bin/xcodebuild", ["-version"])
    }

    public static func showSDK(sdk: String) async throws -> Path {
        Path(try await text("/usr/bin/xcrun", ["--sdk", sdk, "--show-sdk-path"])
            .trimmingCharacters(in: .whitespacesAndNewlines))
    }

    public static func sdkPlatform(sdk: String) async throws -> Path {
        Path(try await text("xcrun", ["--sdk", sdk, "--show-sdk-platform-path"])
            .trimmingCharacters(in: .whitespacesAndNewlines))
    }

    public static func binaryBuildInfo(at binary: Path) async throws -> String {
        try await text("xcrun", ["vtool", "-show-build", binary.string])
    }
}
