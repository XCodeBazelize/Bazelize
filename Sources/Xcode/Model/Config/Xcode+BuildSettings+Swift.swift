import Foundation

extension Xcode.BuildSettings {
    public var swift: SwiftCompiler {
        .init(settings: self)
    }

    /// The part of Xcode's Swift compiler specification that decides how the
    /// language itself behaves: the language mode and the features layered on top
    /// of it.
    ///
    /// None of it matches `swiftc`'s own defaults, so a target whose sources were
    /// written against these settings does not compile without them —
    /// `InternalImportsByDefault` alone decides whether `import SomePackage` makes
    /// the package's public API public in this module or internal to it, and that
    /// is what a retroactive conformance with internal witnesses relies on.
    public struct SwiftCompiler {
        fileprivate let settings: Xcode.BuildSettings

        /// `SWIFT_VERSION`, as `swiftc` spells it.
        ///
        /// Xcode takes a version, the compiler takes a language mode: `5.0` and
        /// `5.5` are both the Swift 5 mode, and `4.2` is the one mode with a
        /// minor of its own.
        public var languageMode: String? {
            guard let value = settings[.swiftVersion], !value.isEmpty else { return nil }

            let components = value.split(separator: ".")
            guard let major = components.first else { return nil }
            if major == "4", components.dropFirst().first == "2" { return "4.2" }
            return String(major)
        }

        /// Everything Xcode turns into a language flag: the mode, the upcoming
        /// features, strict concurrency and strict memory safety.
        public var copts: [String] {
            var copts: [String] = []
            if let languageMode {
                copts += ["-swift-version", languageMode]
            }

            /// A Swift 6 module has the upcoming features on already, and Xcode
            /// drops those settings there: each one is conditional on the effective
            /// language mode being 4, 4.2 or 5.
            guard Self.featureModes.contains(languageMode ?? Self.defaultLanguageMode) else {
                return copts + memorySafetyCopts
            }

            return copts + bareSlashRegexCopts + upcomingFeatureCopts + strictConcurrencyCopts + memorySafetyCopts
        }

        /// `swiftc` compiles in Swift 5 mode unless told otherwise, which is the
        /// fallback Xcode's spec resolves against too.
        private static let defaultLanguageMode = "5"

        /// The language modes in which a feature still has to be asked for.
        private static let featureModes: Set = ["4", "4.2", "5"]

        /// `SWIFT_UPCOMING_FEATURE_*`, as Xcode's `Swift.xcspec` names them. The
        /// setting's suffix is not the feature's name: `IMPORT_OBJC_FORWARD_DECLS`
        /// enables `ImportObjcForwardDeclarations` and
        /// `DISABLE_OUTWARD_ACTOR_ISOLATION` enables `DisableOutwardActorInference`.
        private enum UpcomingFeature: String, CaseIterable {
            case conciseMagicFile = "SWIFT_UPCOMING_FEATURE_CONCISE_MAGIC_FILE"
            case deprecateApplicationMain = "SWIFT_UPCOMING_FEATURE_DEPRECATE_APPLICATION_MAIN"
            case disableOutwardActorInference = "SWIFT_UPCOMING_FEATURE_DISABLE_OUTWARD_ACTOR_ISOLATION"
            case dynamicActorIsolation = "SWIFT_UPCOMING_FEATURE_DYNAMIC_ACTOR_ISOLATION"
            case existentialAny = "SWIFT_UPCOMING_FEATURE_EXISTENTIAL_ANY"
            case forwardTrailingClosures = "SWIFT_UPCOMING_FEATURE_FORWARD_TRAILING_CLOSURES"
            case globalActorIsolatedTypesUsability = "SWIFT_UPCOMING_FEATURE_GLOBAL_ACTOR_ISOLATED_TYPES_USABILITY"
            case globalConcurrency = "SWIFT_UPCOMING_FEATURE_GLOBAL_CONCURRENCY"
            case implicitOpenExistentials = "SWIFT_UPCOMING_FEATURE_IMPLICIT_OPEN_EXISTENTIALS"
            case importObjcForwardDeclarations = "SWIFT_UPCOMING_FEATURE_IMPORT_OBJC_FORWARD_DECLS"
            case inferIsolatedConformances = "SWIFT_UPCOMING_FEATURE_INFER_ISOLATED_CONFORMANCES"
            case inferSendableFromCaptures = "SWIFT_UPCOMING_FEATURE_INFER_SENDABLE_FROM_CAPTURES"
            case internalImportsByDefault = "SWIFT_UPCOMING_FEATURE_INTERNAL_IMPORTS_BY_DEFAULT"
            case isolatedDefaultValues = "SWIFT_UPCOMING_FEATURE_ISOLATED_DEFAULT_VALUES"
            case memberImportVisibility = "SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY"
            case nonfrozenEnumExhaustivity = "SWIFT_UPCOMING_FEATURE_NONFROZEN_ENUM_EXHAUSTIVITY"
            case nonisolatedNonsendingByDefault = "SWIFT_UPCOMING_FEATURE_NONISOLATED_NONSENDING_BY_DEFAULT"
            case regionBasedIsolation = "SWIFT_UPCOMING_FEATURE_REGION_BASED_ISOLATION"

            /// What `-enable-upcoming-feature` takes.
            var name: String {
                switch self {
                case .conciseMagicFile: "ConciseMagicFile"
                case .deprecateApplicationMain: "DeprecateApplicationMain"
                case .disableOutwardActorInference: "DisableOutwardActorInference"
                case .dynamicActorIsolation: "DynamicActorIsolation"
                case .existentialAny: "ExistentialAny"
                case .forwardTrailingClosures: "ForwardTrailingClosures"
                case .globalActorIsolatedTypesUsability: "GlobalActorIsolatedTypesUsability"
                case .globalConcurrency: "GlobalConcurrency"
                case .implicitOpenExistentials: "ImplicitOpenExistentials"
                case .importObjcForwardDeclarations: "ImportObjcForwardDeclarations"
                case .inferIsolatedConformances: "InferIsolatedConformances"
                case .inferSendableFromCaptures: "InferSendableFromCaptures"
                case .internalImportsByDefault: "InternalImportsByDefault"
                case .isolatedDefaultValues: "IsolatedDefaultValues"
                case .memberImportVisibility: "MemberImportVisibility"
                case .nonfrozenEnumExhaustivity: "NonfrozenEnumExhaustivity"
                case .nonisolatedNonsendingByDefault: "NonisolatedNonsendingByDefault"
                case .regionBasedIsolation: "RegionBasedIsolation"
                }
            }

            /// `SWIFT_APPROACHABLE_CONCURRENCY` is not a flag of its own: it is the
            /// default value of these five settings.
            var isApproachableConcurrency: Bool {
                switch self {
                case .disableOutwardActorInference,
                     .globalActorIsolatedTypesUsability,
                     .inferIsolatedConformances,
                     .inferSendableFromCaptures,
                     .nonisolatedNonsendingByDefault:
                    true
                default:
                    false
                }
            }
        }

        private var approachableConcurrency: Bool {
            settings[.swiftApproachableConcurrency] == "YES"
        }

        private var upcomingFeatureCopts: [String] {
            UpcomingFeature.allCases.flatMap { feature -> [String] in
                let fallback = approachableConcurrency && feature.isApproachableConcurrency
                switch settings[feature.rawValue] ?? (fallback ? "YES" : "NO") {
                case "YES":
                    return ["-enable-upcoming-feature", feature.name]
                /// A migrating feature is diagnosed but not enforced, and the
                /// compiler spells that as a suffix on the feature's name.
                case "MIGRATE":
                    return ["-enable-upcoming-feature", "\(feature.name):migrate"]
                default:
                    return []
                }
            }
        }

        /// `SWIFT_ENABLE_BARE_SLASH_REGEX`, which Xcode turns on by default and
        /// `swiftc` does not.
        private var bareSlashRegexCopts: [String] {
            settings[.swiftEnableBareSlashRegex] == "NO" ? [] : ["-enable-bare-slash-regex"]
        }

        /// `SWIFT_STRICT_CONCURRENCY`: anything above `minimal` but short of
        /// `complete` is a frontend flag, `complete` is the upcoming feature.
        private var strictConcurrencyCopts: [String] {
            switch settings[.swiftStrictConcurrency] {
            case "targeted":
                return ["-strict-concurrency=targeted"]
            case .some(let value) where value != "minimal" && !value.isEmpty:
                return ["-enable-upcoming-feature", "StrictConcurrency"]
            default:
                return []
            }
        }

        /// `SWIFT_STRICT_MEMORY_SAFETY`, which a Swift 6 module still has to ask
        /// for.
        private var memorySafetyCopts: [String] {
            switch settings[.swiftStrictMemorySafety] {
            case "YES":
                return ["-strict-memory-safety"]
            case "MIGRATE":
                return ["-strict-memory-safety:migrate"]
            default:
                return []
            }
        }
    }
}
