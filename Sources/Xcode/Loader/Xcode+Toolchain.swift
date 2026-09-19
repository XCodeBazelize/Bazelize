import Foundation

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
enum Toolchain {
    /// What Xcode would set for a target built against `sdk`, which is the
    /// project's `SDKROOT`.
    static func settings(sdk: String?) -> [String: String] {
        guard let platform = canonical(sdk), let sdk = sdks[platform] else { return xcode }

        return xcode.merging([
            "PLATFORM_NAME": platform,
            "SDK_NAME": sdk.name,
            "SDK_VERSION": sdk.version,
        ]) { _, new in new }
    }

    // MARK: Private

    private struct SDK: Decodable {
        let canonicalName: String
        let sdkVersion: String
        let platform: String
    }

    /// `SDKROOT` is a platform name (`macosx`), a canonical SDK name
    /// (`macosx26.0`), `auto`, or a path. Only a name identifies a platform
    /// without building the target first.
    private static func canonical(_ sdk: String?) -> String? {
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

    /// Every installed SDK, by platform: one `xcodebuild -showsdks` answers for
    /// all of them, and the newest of a platform is the one Xcode builds with.
    private static let sdks: [String: (name: String, version: String)] = {
        guard
            let output = run("xcodebuild", ["-showsdks", "-json"]),
            let sdks = try? JSONDecoder().decode([SDK].self, from: Data(output.utf8))
        else {
            return [:]
        }

        var result: [String: (name: String, version: String)] = [:]
        for sdk in sdks {
            let current = result[sdk.platform]
            if let current, current.version.compare(sdk.sdkVersion, options: .numeric) != .orderedAscending {
                continue
            }
            result[sdk.platform] = (name: sdk.canonicalName, version: sdk.sdkVersion)
        }

        return result
    }()

    /// How Xcode spells its own version: a four digit number, so 27.0 is `2700`
    /// and 14.3.1 is `1431`. `MAJOR` keeps only the major, `MINOR` drops the
    /// patch.
    static func settings(xcodeVersion version: String) -> [String: String] {
        let components = version.split(separator: ".").compactMap { Int($0) }
        guard let major = components.first else { return [:] }
        let minor = components.count > 1 ? components[1] : 0
        let patch = components.count > 2 ? components[2] : 0

        return [
            "XCODE_VERSION_ACTUAL": "\(major * 100 + minor * 10 + patch)",
            "XCODE_VERSION_MAJOR": "\(major * 100)",
            "XCODE_VERSION_MINOR": "\(major * 100 + minor * 10)",
        ]
    }

    /// `xcodebuild -version` says `Xcode 27.0` on its first line.
    private static let xcode: [String: String] = {
        guard
            let output = run("xcodebuild", ["-version"]),
            let version = output.split(separator: "\n").first?.split(separator: " ").last
        else {
            return [:]
        }

        return settings(xcodeVersion: String(version))
    }()

    /// A toolchain that cannot be asked leaves the settings unset, which is what
    /// they already were.
    private static func run(_ executable: String, _ arguments: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/\(executable)")
        process.arguments = arguments

        let output = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            return nil
        }

        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }

        return String(data: data, encoding: .utf8)
    }
}
