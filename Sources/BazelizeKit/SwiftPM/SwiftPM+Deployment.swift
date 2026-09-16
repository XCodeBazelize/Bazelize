//
//  SwiftPM+Deployment.swift
//
//
//  The platform version a package's targets are compiled at.
//

import Foundation
@preconcurrency import PathKit
import XCode2
import Subprocess
import Util

extension SwiftPM {
    /// Which platform version each of a package's targets is compiled at.
    ///
    /// SwiftPM takes the higher of what the package declares and what the consumer
    /// asks for. A package target here is compiled at the project's deployment
    /// target, because the version lives in the platform transition of the bundle
    /// rule that pulls the target in, and a library rule has no version of its
    /// own. A package that requires more than the project does therefore fails to
    /// compile, and saying so beats an availability error deep in someone else's
    /// source.
    struct Deployment: Sendable {
        /// The project's deployment target per platform, keyed the way a manifest
        /// names the platform.
        let project: [String: String]

        /// What the package requires: its own declaration, or the oldest version
        /// SwiftPM builds that platform for.
        func required(_ package: Package, platform: String) -> String? {
            if let declared = package.manifest.platforms.first(where: { $0.platformName == platform }) {
                return declared.version
            }

            return Self.oldest[platform]
        }

        /// The platforms a package would be compiled for at a version the project
        /// does not provide.
        func unmet(_ package: Package) -> [(platform: String, required: String, project: String)] {
            project.keys.sorted().compactMap { platform in
                guard
                    let floor = project[platform],
                    let required = required(package, platform: platform),
                    Self.isNewer(required, than: floor)
                else {
                    return nil
                }

                return (platform, required, floor)
            }
        }

        /// SwiftPM's own floors, the versions it builds a platform for when a
        /// package declares nothing.
        ///
        /// They follow the installed toolchain rather than a table of our own:
        /// SwiftPM reads them out of the SDK when it can, and the table is what it
        /// falls back to.
        static let oldest: [String: String] = [
            "macos": "12.0",
            "maccatalyst": "15.0",
            "ios": "15.0",
            "tvos": "15.0",
            "watchos": "9.0",
            "visionos": "1.0",
            "driverkit": "21.0",
        ]

        static func isNewer(_ version: String, than other: String) -> Bool {
            let left = components(version)
            let right = components(other)

            for index in 0 ..< max(left.count, right.count) {
                let lhs = index < left.count ? left[index] : 0
                let rhs = index < right.count ? right[index] : 0
                if lhs != rhs { return lhs > rhs }
            }

            return false
        }

        private static func components(_ version: String) -> [Int] {
            version.split(separator: ".").map { Int($0) ?? 0 }
        }
    }
}

extension SwiftPM.Deployment {
    /// The oldest version the installed SDK can build a platform for.
    ///
    /// This is how SwiftPM answers the question for a platform it has no floor
    /// for: the deployment target of the `XCTest` the SDK ships is the oldest
    /// version that SDK supports. A platform the toolchain does not have stays at
    /// SwiftPM's own floor.
    static func sdkFloor(platform: String) async -> String? {
        guard let sdk = sdkName[platform] else { return nil }

        guard
            let platformPath = try? await run("xcrun", ["--sdk", sdk, "--show-sdk-platform-path"]),
            !platformPath.isEmpty
        else {
            return nil
        }

        let binary = Path(platformPath.trimmingCharacters(in: .whitespacesAndNewlines))
            + "Developer/Library/Frameworks/XCTest.framework/XCTest"
        guard binary.exists else { return nil }

        guard let build = try? await run("xcrun", ["vtool", "-show-build", binary.string]) else {
            return nil
        }

        /// `vtool` prints the load command as `platform IOS` followed by
        /// `minos 15.0`.
        var seen = false
        for line in build.split(separator: "\n") {
            let statement = line.trimmingCharacters(in: .whitespaces)
            if statement.hasPrefix("platform ") {
                seen = statement.hasSuffix(platformName[platform] ?? "")
                continue
            }
            if seen, statement.hasPrefix("minos ") {
                return String(statement.dropFirst("minos ".count))
            }
        }

        return nil
    }

    /// The name a manifest gives the platform an SDK builds for.
    static func platform(of sdk: SDK) -> String? {
        switch sdk {
        case .iOS:
            return "ios"
        case .macOS:
            return "macos"
        case .tvOS:
            return "tvos"
        case .watchOS:
            return "watchos"
        case .driverKit:
            return "driverkit"
        case .auto:
            return nil
        }
    }

    private static let sdkName: [String: String] = [
        "macos": "macosx",
        "maccatalyst": "macosx",
        "ios": "iphoneos",
        "tvos": "appletvos",
        "watchos": "watchos",
        "visionos": "xros",
    ]

    private static let platformName: [String: String] = [
        "macos": "MACOS",
        "maccatalyst": "MACCATALYST",
        "ios": "IOS",
        "tvos": "TVOS",
        "watchos": "WATCHOS",
        "visionos": "XROS",
    ]

    private static func run(_ executable: String, _ arguments: [String]) async throws -> String {
        let result = try await Subprocess.run(
            .name(executable),
            arguments: Arguments(arguments),
            output: .string(limit: 1024 * 1024))

        guard result.terminationStatus.isSuccess else { return "" }
        return result.standardOutput ?? ""
    }
}
