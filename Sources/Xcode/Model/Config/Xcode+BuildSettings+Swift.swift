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
            guard let value = settings["SWIFT_VERSION"], !value.isEmpty else { return nil }

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
        private static let featureModes: Set<String> = ["4", "4.2", "5"]

        /// `SWIFT_UPCOMING_FEATURE_*` and the feature each one names, as Xcode's
        /// `Swift.xcspec` maps them. The setting's suffix is not the feature's name:
        /// `IMPORT_OBJC_FORWARD_DECLS` enables `ImportObjcForwardDeclarations` and
        /// `DISABLE_OUTWARD_ACTOR_ISOLATION` enables `DisableOutwardActorInference`.
        private static let upcomingFeatures: KeyValuePairs<String, String> = [
            "CONCISE_MAGIC_FILE": "ConciseMagicFile",
            "DEPRECATE_APPLICATION_MAIN": "DeprecateApplicationMain",
            "DISABLE_OUTWARD_ACTOR_ISOLATION": "DisableOutwardActorInference",
            "DYNAMIC_ACTOR_ISOLATION": "DynamicActorIsolation",
            "EXISTENTIAL_ANY": "ExistentialAny",
            "FORWARD_TRAILING_CLOSURES": "ForwardTrailingClosures",
            "GLOBAL_ACTOR_ISOLATED_TYPES_USABILITY": "GlobalActorIsolatedTypesUsability",
            "GLOBAL_CONCURRENCY": "GlobalConcurrency",
            "IMPLICIT_OPEN_EXISTENTIALS": "ImplicitOpenExistentials",
            "IMPORT_OBJC_FORWARD_DECLS": "ImportObjcForwardDeclarations",
            "INFER_ISOLATED_CONFORMANCES": "InferIsolatedConformances",
            "INFER_SENDABLE_FROM_CAPTURES": "InferSendableFromCaptures",
            "INTERNAL_IMPORTS_BY_DEFAULT": "InternalImportsByDefault",
            "ISOLATED_DEFAULT_VALUES": "IsolatedDefaultValues",
            "MEMBER_IMPORT_VISIBILITY": "MemberImportVisibility",
            "NONFROZEN_ENUM_EXHAUSTIVITY": "NonfrozenEnumExhaustivity",
            "NONISOLATED_NONSENDING_BY_DEFAULT": "NonisolatedNonsendingByDefault",
            "REGION_BASED_ISOLATION": "RegionBasedIsolation",
        ]

        /// `SWIFT_APPROACHABLE_CONCURRENCY` is not a flag of its own: it is the
        /// default value of these five settings.
        private static let approachableConcurrencyFeatures: Set<String> = [
            "DISABLE_OUTWARD_ACTOR_ISOLATION",
            "GLOBAL_ACTOR_ISOLATED_TYPES_USABILITY",
            "INFER_ISOLATED_CONFORMANCES",
            "INFER_SENDABLE_FROM_CAPTURES",
            "NONISOLATED_NONSENDING_BY_DEFAULT",
        ]

        private var approachableConcurrency: Bool {
            settings["SWIFT_APPROACHABLE_CONCURRENCY"] == "YES"
        }

        private var upcomingFeatureCopts: [String] {
            Self.upcomingFeatures.flatMap { suffix, feature -> [String] in
                let fallback = approachableConcurrency && Self.approachableConcurrencyFeatures.contains(suffix)
                switch settings["SWIFT_UPCOMING_FEATURE_\(suffix)"] ?? (fallback ? "YES" : "NO") {
                case "YES":
                    return ["-enable-upcoming-feature", feature]
                /// A migrating feature is diagnosed but not enforced, and the
                /// compiler spells that as a suffix on the feature's name.
                case "MIGRATE":
                    return ["-enable-upcoming-feature", "\(feature):migrate"]
                default:
                    return []
                }
            }
        }

        /// `SWIFT_ENABLE_BARE_SLASH_REGEX`, which Xcode turns on by default and
        /// `swiftc` does not.
        private var bareSlashRegexCopts: [String] {
            settings["SWIFT_ENABLE_BARE_SLASH_REGEX"] == "NO" ? [] : ["-enable-bare-slash-regex"]
        }

        /// `SWIFT_STRICT_CONCURRENCY`: anything above `minimal` but short of
        /// `complete` is a frontend flag, `complete` is the upcoming feature.
        private var strictConcurrencyCopts: [String] {
            switch settings["SWIFT_STRICT_CONCURRENCY"] {
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
            switch settings["SWIFT_STRICT_MEMORY_SAFETY"] {
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
