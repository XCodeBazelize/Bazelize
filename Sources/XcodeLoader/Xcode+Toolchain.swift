import Commands
import Foundation
import Xcode

// MARK: - Toolchain

/// The build settings Xcode fills in from the installed toolchain rather than
/// from the project.
///
/// A project references them as freely as its own: iina writes
/// `$(SDK_VERSION)` and `$(XCODE_VERSION_ACTUAL)` into its `Info.plist`, and
/// neither appears anywhere in the project file — Xcode is the one that knows
/// them, so nobody can be asked to type them in.
///
/// `xcodebuild -showBuildSettings` knows every one of them, but it resolves the
/// package graph and takes some ten seconds per target, so the values are read
/// from the toolchain directly: two commands for a whole run, both of which
/// answer for every platform at once.
struct Toolchain: Sendable {
    /// What Xcode would set for a target built against `sdk`, which is the
    /// project's `SDKROOT`.
    func settings(sdk: String?) -> [Xcode.BuildSettings.Key: String] {
        guard let platform = canonical(sdk), let sdk = sdks[platform] else { return xcode }

        return xcode.merging([
            .platformName: platform,
            .sdkName: sdk.name,
            .sdkVersion: sdk.version,
        ]) { _, new in new }
    }

    // MARK: Private

    struct SDK: Decodable, Sendable {
        let canonicalName: String
        let sdkVersion: String
        let platform: String
    }

    /// `SDKROOT` is a platform name (`macosx`), a canonical SDK name
    /// (`macosx26.0`), `auto`, or a path. Only a name identifies a platform
    /// without building the target first.
    private func canonical(_ sdk: String?) -> String? {
        guard
            let sdk = sdk?.lowercased(),
            !sdk.isEmpty,
            sdk != "auto",
            !sdk.contains("/")
        else {
            return nil
        }

        return sdks[sdk] != nil ? sdk : sdks.first { _, value in value.name == sdk }?.key
    }

    private let sdks: [String: (name: String, version: String)]
    private let xcode: [Xcode.BuildSettings.Key: String]

    // One immutable discovery shared by concurrent project loads. A cancelled
    // consumer must not cancel discovery used by another consumer.
    private static let installed = Task { await discover() }

    static func load() async -> Self {
        await installed.value
    }

    private static func discover() async -> Self {
        async let sdkQuery = try? JSONDecoder().decode([SDK].self, from: Commands.xcodebuild.installedSDKs())
        async let versionQuery = try? Commands.xcodebuild.xcodeVersion()
        let (sdks, output) = await (sdkQuery, versionQuery)
        let version = output?.split(separator: "\n").first?.split(separator: " ").last
        let xcode = version.map { settings(xcodeVersion: String($0)) } ?? [:]
        guard let sdks
        else {
            return .init(sdks: [:], xcode: xcode)
        }

        var result: [String: (name: String, version: String)] = [:]
        for sdk in sdks {
            let current = result[sdk.platform]
            if let current, current.version.compare(sdk.sdkVersion, options: .numeric) != .orderedAscending {
                continue
            }
            result[sdk.platform] = (name: sdk.canonicalName, version: sdk.sdkVersion)
        }

        return .init(sdks: result, xcode: xcode)
    }

    /// How Xcode spells its own version: a four digit number, so 27.0 is `2700`
    /// and 14.3.1 is `1431`. `MAJOR` keeps only the major, `MINOR` drops the
    /// patch.
    static func settings(xcodeVersion version: String) -> [Xcode.BuildSettings.Key: String] {
        let components = version.split(separator: ".").compactMap { Int($0) }
        guard let major = components.first else { return [:] }
        let minor = components.count > 1 ? components[1] : 0
        let patch = components.count > 2 ? components[2] : 0

        return [
            .xcodeVersionActual: "\(major * 100 + minor * 10 + patch)",
            .xcodeVersionMajor: "\(major * 100)",
            .xcodeVersionMinor: "\(major * 100 + minor * 10)",
        ]
    }
}
