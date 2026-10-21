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

// MARK: - Xcode.BuildSettings

extension Xcode {
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

        /// Values for the settings this configuration does not state itself.
        func with(defaults: [String: String]) -> BuildSettings {
            .init(
                name: name,
                setting: setting.merging(defaults) { current, _ in
                    current
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

extension Xcode.BuildSettings {
    public var swiftVersion: String? { self["SWIFT_VERSION"] }

    /// `SWIFT_DEFAULT_ACTOR_ISOLATION`: the module-wide default Xcode compiles with
    /// (SE-0466). Code written against `MainActor` by default does not compile
    /// without it.
    public var swiftDefaultActorIsolation: String? {
        guard let value = self["SWIFT_DEFAULT_ACTOR_ISOLATION"], !value.isEmpty else { return nil }
        return value
    }

    /// Everything Swift compiles with `-D`: the conditions Xcode dedicates a
    /// setting to, plus any `-D` smuggled through `OTHER_SWIFT_FLAGS`.
    ///
    /// `SWIFT_ACTIVE_COMPILATION_CONDITIONS` is how a project spells `#if FEATURE`
    /// for Swift — UTM decides which SPICE module to import with it.
    public var swiftDefines: [String] {
        var result: [String] = []
        for define in Self.split(self["SWIFT_ACTIVE_COMPILATION_CONDITIONS"])
            + Self.swiftFlags(self["OTHER_SWIFT_FLAGS"]).defines
            where !result.contains(define)
        {
            /// `swiftc` rejects anything that is not an identifier, and a project
            /// routinely leaves a build setting reference in here — iina spells one
            /// condition `$AVAILABLE_$(SDK_VERSION_MAJOR)`.
            guard define.range(of: #"^[A-Za-z_][A-Za-z0-9_]*$"#, options: .regularExpression) != nil else {
                continue
            }
            result.append(define)
        }
        return result
    }

    /// What `OTHER_SWIFT_FLAGS` says apart from the conditions `swiftDefines`
    /// already took out of it. A project reaches the frontend through this
    /// setting — `-Xfrontend`, `-enable-experimental-feature`, `-Xcc` — and a
    /// module written against those flags does not compile without them.
    public var otherSwiftFlags: [String] {
        Self.swiftFlags(self["OTHER_SWIFT_FLAGS"]).flags
    }

    /// `OTHER_SWIFT_FLAGS` as the two things it holds: the conditions it
    /// defines, and every other flag in the order it was written.
    ///
    /// A `-D` is Swift's own define, but the one in `-Xcc -DFOO` belongs to the
    /// clang importer and stays a flag — the header it guards is not compiled
    /// by `swiftc`.
    private static func swiftFlags(_ value: String?) -> (defines: [String], flags: [String]) {
        var defines: [String] = []
        var flags: [String] = []
        var remaining = split(value).makeIterator()

        while let flag = remaining.next() {
            if flag == "-D" {
                /// `-D ABC`
                if let define = remaining.next() { defines.append(define) }
            } else if flag.hasPrefix("-D") {
                /// `-DABC`
                defines.append(String(flag.dropFirst(2)))
            } else if passthroughPairs.contains(flag) {
                flags.append(flag)
                if let argument = remaining.next() { flags.append(argument) }
            } else {
                flags.append(flag)
            }
        }

        return (defines, flags)
    }

    /// Flags whose argument is another tool's, and is therefore read by
    /// neither this type nor `swiftc` itself.
    private static let passthroughPairs: Set<String> = ["-Xcc", "-Xfrontend", "-Xllvm", "-Xclang-linker"]

    /// `OTHER_CFLAGS`: what every C-family compile of the target takes.
    public var otherCFlags: [String] {
        Self.split(self["OTHER_CFLAGS"])
    }

    /// `OTHER_CPLUSPLUSFLAGS`: what the C++ compiles take on top of
    /// `OTHER_CFLAGS`, which is how Xcode spells a C++ dialect a C file would
    /// be rejected for.
    public var otherCPlusPlusFlags: [String] {
        Self.split(self["OTHER_CPLUSPLUSFLAGS"])
    }

    /// One build setting's flags: whitespace-separated, unquoted, without
    /// Xcode's `$(inherited)` marker.
    private static func split(_ value: String?) -> [String] {
        (value ?? "")
            .split(separator: " ")
            .map { String($0).unquoted }
            .filter { !$0.isEmpty && $0 != "$(inherited)" }
    }
    public var bridgingHeader: String? { self["SWIFT_OBJC_BRIDGING_HEADER"] }

    /// `GCC_PREFIX_HEADER`: a header Xcode force-includes into every C-family
    /// compile of the target, which is how a source file gets away without
    /// importing the framework it uses.
    public var prefixHeader: String? {
        guard let header = self["GCC_PREFIX_HEADER"]?.unquoted, !header.isEmpty else { return nil }
        return header
    }

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

    /// `OTHER_LDFLAGS`, without Xcode's `$(inherited)` marker.
    public var otherLinkerFlags: [String] {
        (self["OTHER_LDFLAGS"] ?? "")
            .split(separator: " ")
            .map { flag in
                String(flag).unquoted
            }
            .filter { !$0.isEmpty && $0 != "$(inherited)" }
    }

    /// `GCC_PREPROCESSOR_DEFINITIONS`, without Xcode's `$(inherited)` marker.
    ///
    /// Xcode passes each entry through a shell, so a value is often quoted
    /// (`ID='@"com.example"'`); Bazel hands `defines` to the compiler directly and
    /// the quotes would end up inside the macro.
    public var preprocessorDefinitions: [String] {
        (self["GCC_PREPROCESSOR_DEFINITIONS"] ?? "")
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty && $0 != "$(inherited)" }
            .map { definition in
                guard let separator = definition.firstIndex(of: "=") else { return definition }
                let key = definition[..<separator]
                let value = definition[definition.index(after: separator)...]
                return "\(key)=\(value.unquoted)"
            }
    }

    public var testTargetName: String? { self["TEST_TARGET_NAME"] }
    public var testHost: String? { self["TEST_HOST"] }
    public var bundleLoader: String? { self["BUNDLE_LOADER"] }
    public var enableModules: Bool { self["CLANG_ENABLE_MODULES"] == "YES" }

    /// `MACH_O_TYPE`: how a target's objects are linked — `staticlib` makes a
    /// framework target a static one, which has no bundle to load at runtime.
    public var machOType: String? { self["MACH_O_TYPE"] }
}

extension StringProtocol {
    /// Strips one layer of shell quoting.
    fileprivate var unquoted: String {
        for quote in ["'", "\""] where hasPrefix(quote) && hasSuffix(quote) && count > 1 {
            return String(dropFirst().dropLast())
        }
        return String(self)
    }
}

extension Xcode.BuildSettings {
    /// Xcode spells a reference `$(NAME)` or `${NAME}` and allows a modifier:
    /// `$(PRODUCT_NAME:rfc1034identifier)`.
    private static let referencePattern = #"\$[({]([A-Za-z0-9_]+)(?::([A-Za-z0-9_]+))?[)}]"#

    private func resolved(_ value: String?, visited: Set<String>) -> String? {
        guard let value else { return nil }

        guard let regex = try? NSRegularExpression(pattern: Self.referencePattern) else { return value }

        let matches = regex.matches(
            in: value,
            range: NSRange(value.startIndex..., in: value))
        guard !matches.isEmpty else { return value }

        var result = value
        for match in matches.reversed() {
            guard
                let wholeRange = Range(match.range(at: 0), in: value),
                let keyRange = Range(match.range(at: 1), in: value)
            else {
                continue
            }

            let key = String(value[keyRange])
            guard !visited.contains(key), let replacement = resolved(setting[key], visited: visited.union([key])) else {
                continue
            }

            let modifier = Range(match.range(at: 2), in: value).map { String(value[$0]) }
            result.replaceSubrange(wholeRange, with: Self.apply(modifier, to: replacement))
        }

        return result
    }

    private static func apply(_ modifier: String?, to value: String) -> String {
        switch modifier {
        case "rfc1034identifier":
            return value.map { character in
                character.isLetter || character.isNumber || character == "." || character == "-"
                    ? String(character)
                    : "-"
            }.joined()
        case "identifier", "c99extidentifier":
            return value.map { character in
                character.isLetter || character.isNumber ? String(character) : "_"
            }.joined()
        case "lower":
            return value.lowercased()
        case "upper":
            return value.uppercased()
        default:
            return value
        }
    }
}
