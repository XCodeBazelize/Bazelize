//
//  SwiftPM+Deployment.swift
//
//
//  The platform version a package's targets are compiled at.
//

import Commands
import Foundation
@preconcurrency import PathKit
import Util
import Xcode

// MARK: - SwiftPM.ApplePlatform

extension SwiftPM {
    /// An Apple platform a manifest declares a version for, spelled the way the
    /// manifest spells it.
    enum ApplePlatform: String, CaseIterable, Comparable, Sendable {
        case driverKit = "driverkit"
        case iOS = "ios"
        case macCatalyst = "maccatalyst"
        case macOS = "macos"
        case tvOS = "tvos"
        case visionOS = "visionos"
        case watchOS = "watchos"

        /// The platform an SDK builds for.
        init?(sdk: SDK) {
            switch sdk {
            case .iOS:
                self = .iOS
            case .macOS:
                self = .macOS
            case .tvOS:
                self = .tvOS
            case .watchOS:
                self = .watchOS
            case .driverKit:
                self = .driverKit
            case .auto:
                return nil
            }
        }

        static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        /// SwiftPM's own floor, the version it builds the platform for when a
        /// package declares nothing.
        ///
        /// They follow the installed toolchain rather than a table of our own:
        /// SwiftPM reads them out of the SDK when it can, and the table is what it
        /// falls back to.
        var swiftPMFloor: String {
            switch self {
            case .macOS: "12.0"
            case .macCatalyst: "15.0"
            case .iOS: "15.0"
            case .tvOS: "15.0"
            case .watchOS: "9.0"
            case .visionOS: "1.0"
            case .driverKit: "21.0"
            }
        }

        /// The SDK whose platform directory holds the platform's `XCTest`.
        private var sdkName: String? {
            switch self {
            case .macOS, .macCatalyst: "macosx"
            case .iOS: "iphoneos"
            case .tvOS: "appletvos"
            case .watchOS: "watchos"
            case .visionOS: "xros"
            case .driverKit: nil
            }
        }

        /// How a Mach-O build-version load command names the platform.
        private var machOName: String? {
            switch self {
            case .macOS: "MACOS"
            case .macCatalyst: "MACCATALYST"
            case .iOS: "IOS"
            case .tvOS: "TVOS"
            case .watchOS: "WATCHOS"
            case .visionOS: "XROS"
            case .driverKit: nil
            }
        }

        /// The oldest version the installed SDK can build the platform for.
        ///
        /// This is how SwiftPM answers the question for a platform it has no floor
        /// for: the deployment target of the `XCTest` the SDK ships is the oldest
        /// version that SDK supports. A platform the toolchain does not have stays at
        /// SwiftPM's own floor.
        func sdkFloor() async -> String? {
            guard let sdkName, let machOName else { return nil }

            guard
                let platformPath = try? await Commands.sdkPlatform(sdk: sdkName)
            else {
                return nil
            }

            let binary = platformPath + "Developer/Library/Frameworks/XCTest.framework/XCTest"
            guard binary.exists else { return nil }

            guard let build = try? await Commands.binaryBuildInfo(at: binary) else {
                return nil
            }

            /// `vtool` prints the load command as `platform IOS` followed by
            /// `minos 15.0`.
            var seen = false
            for line in build.split(separator: "\n") {
                let statement = line.trimmingCharacters(in: .whitespaces)
                if statement.hasPrefix("platform ") {
                    seen = statement.hasSuffix(machOName)
                    continue
                }
                if seen, statement.hasPrefix("minos ") {
                    return String(statement.dropFirst("minos ".count))
                }
            }

            return nil
        }
    }
}

extension SwiftPM.Platform {
    /// The Apple platform this declaration is for; `nil` for any other.
    var apple: SwiftPM.ApplePlatform? {
        .init(rawValue: platformName)
    }
}

// MARK: - SwiftPM.Deployment

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
        /// A version per platform.
        typealias Floors = [ApplePlatform: String]

        /// The project's deployment target per platform.
        let project: Floors

        /// What the package requires: its own declaration, or the oldest version
        /// SwiftPM builds that platform for.
        func required(_ package: Package, platform: ApplePlatform) -> String? {
            if let declared = package.manifest.platforms.first(where: { $0.apple == platform }) {
                return declared.version
            }

            return platform.swiftPMFloor
        }

        /// The platforms where the package asks for more than the project provides.
        ///
        /// Only a version the manifest states counts. SwiftPM raises both sides to
        /// its own floor before comparing them — a package that declares nothing is
        /// never the reason a graph is rejected — so the default is not something to
        /// warn about.
        func unmet(_ package: Package) -> [(platform: ApplePlatform, required: String, project: String)] {
            project.keys.sorted().compactMap { platform in
                guard
                    let floor = project[platform],
                    let declared = package.manifest.platforms
                        .first(where: { $0.apple == platform })?
                        .version,
                    Self.isNewer(declared, than: floor)
                else {
                    return nil
                }

                return (platform, declared, floor)
            }
        }

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

// MARK: - Floors

extension SwiftPM.Deployment {
    /// Per platform, the newest version declared for it. An empty or missing
    /// version declares nothing.
    static func newest(_ declarations: some Sequence<(SwiftPM.ApplePlatform, String?)>) -> Floors {
        fold(declarations) { candidate, kept in isNewer(candidate, than: kept) }
    }

    /// Per platform, the oldest version declared for it. An empty or missing
    /// version declares nothing.
    static func oldest(_ declarations: some Sequence<(SwiftPM.ApplePlatform, String?)>) -> Floors {
        fold(declarations) { candidate, kept in isNewer(kept, than: candidate) }
    }

    private static func fold(
        _ declarations: some Sequence<(SwiftPM.ApplePlatform, String?)>,
        replaces: (String, String) -> Bool)
        -> Floors
    {
        var floors: Floors = [:]
        for (platform, version) in declarations {
            guard let version, !version.isEmpty else { continue }
            if let kept = floors[platform], !replaces(version, kept) { continue }
            floors[platform] = version
        }
        return floors
    }

    /// The versions a package's targets end up compiled at: the lowest deployment
    /// target of the project's own targets, per platform, because that is the one
    /// a package has to be buildable against.
    ///
    /// A platform no target of the project builds for cannot fail, so it is left
    /// out. Where the project says nothing, the oldest version the installed SDK
    /// can build for stands in — the same answer SwiftPM reads out of the SDK.
    static func of(_ project: borrowing Project) async -> Self {
        var declared: [(SwiftPM.ApplePlatform, String?)] = []
        var built: Set<SwiftPM.ApplePlatform> = []

        project.forEachTarget { target in
            if let platform = target.platformSDK.flatMap(SwiftPM.ApplePlatform.init(sdk:)) {
                built.insert(platform)
            }

            declared += [
                (.macOS, target.prefer(\.platform.macOS)),
                (.iOS, target.prefer(\.platform.iOS)),
                (.tvOS, target.prefer(\.platform.tvOS)),
                (.watchOS, target.prefer(\.platform.watchOS)),
            ]
        }

        var floors = oldest(declared)
        /// A platform the project builds for without saying which version: the
        /// oldest the installed SDK can build is what Xcode would use.
        for platform in built.sorted() where floors[platform] == nil {
            floors[platform] = await platform.sdkFloor()
        }

        return .init(project: floors)
    }
}

// MARK: - SwiftPM.Workspace

extension SwiftPM.Workspace {
    /// The deployment floor of the resolved graph, per platform.
    ///
    /// SwiftPM compiles every package of a graph at the highest version any of
    /// them declares: a package that asks for more raises the floor for all of
    /// them, which is why a graph it is part of is built against that.
    var deploymentFloors: SwiftPM.Deployment.Floors {
        SwiftPM.Deployment.newest(packages.flatMap { package in
            package.manifest.platforms.compactMap { declared in
                declared.apple.map { ($0, declared.version) }
            }
        })
    }

    /// Which package directory declares each product, for the target rules
    /// that have to name one.
    ///
    /// A product name is the package's own, so two packages can ship one of
    /// the same name; such a name answers for neither, because nothing in an
    /// Xcode target says which package it meant.
    var packageDirectoryByProduct: [String: String] {
        var directories: [String: String] = [:]
        var ambiguous: Set<String> = []

        for package in packages {
            for product in package.manifest.products {
                if let existing = directories[product.name], existing != package.directory {
                    ambiguous.insert(product.name)
                    continue
                }
                directories[product.name] = package.directory
            }
        }

        for name in ambiguous {
            directories[name] = nil
        }

        return directories
    }
}
