//
//  Commands+Xcrun.swift
//
//  SDK paths and binary build information from the selected Xcode.
//

import Foundation
@preconcurrency import PathKit

extension Commands.xcrun {
    public static func showSDK(sdk: String) async throws -> Path {
        Path(try await Commands.text("/usr/bin/xcrun", ["--sdk", sdk, "--show-sdk-path"])
            .trimmingCharacters(in: .whitespacesAndNewlines))
    }

    public static func sdkPlatform(sdk: String) async throws -> Path {
        Path(try await Commands.text("xcrun", ["--sdk", sdk, "--show-sdk-platform-path"])
            .trimmingCharacters(in: .whitespacesAndNewlines))
    }

    public static func binaryBuildInfo(at binary: Path) async throws -> String {
        try await Commands.text("xcrun", ["vtool", "-show-build", binary.string])
    }
}
