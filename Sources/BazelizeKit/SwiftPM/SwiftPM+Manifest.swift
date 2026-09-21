//
//  SwiftPM+Manifest.swift
//
//
//  The subset of `swift package dump-package` the generator needs.
//

import Foundation

// MARK: - SwiftPM

/// Generating Bazel rules for the Swift packages a project depends on.
public enum SwiftPM { }

extension SwiftPM {
    /// A package manifest, as `swift package dump-package` prints it.
    ///
    /// The dump is the manifest after SwiftPM evaluated it, so conditionals and
    /// defaults are already applied; reading it beats re-implementing
    /// `Package.swift`.
    struct Manifest: Decodable {
        let name: String
        let platforms: [Platform]
        let products: [PackageProduct]
        var targets: [PackageTarget]
        let dependencies: [Dependency]
        /// The package's own build-time options.
        let traits: [Trait]
        let cLanguageStandard: String?
        let cxxLanguageStandard: String?
        /// `{"_version": "6.0.0"}`: which `PackageDescription` the manifest was
        /// written against, which a plugin has to be compiled against too.
        let toolsVersion: String

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: AnyKey.self)
            name = try container.decode(String.self, forKey: AnyKey("name"))
            platforms = container.list(Platform.self, "platforms")
            products = container.list(PackageProduct.self, "products")
            targets = container.list(PackageTarget.self, "targets")
            dependencies = container.list(Dependency.self, "dependencies")
            traits = container.list(Trait.self, "traits")
            cLanguageStandard = container.value(String.self, "cLanguageStandard")
            cxxLanguageStandard = container.value(String.self, "cxxLanguageStandard")
            toolsVersion = container.value([String: String].self, "toolsVersion")?["_version"] ?? "5.9.0"
        }

        /// The manifest with every setting that does not apply removed, so
        /// nothing downstream has to know a condition exists.
        ///
        /// `platforms` empty means the caller does not know which platforms are
        /// built, and a platform condition is then left alone.
        func resolving(traits: Set<String>, platforms: Set<String>) -> Manifest {
            var resolved = self
            resolved.targets = targets.map { target in
                var target = target
                target.settings = target.settings.filter { setting in
                    setting.applies(traits: traits, platforms: platforms)
                }
                target.dependencies = target.dependencies.filter { dependency in
                    dependency.applies(traits: traits, platforms: platforms)
                }
                return target
            }
            return resolved
        }
    }

    struct Platform: Decodable {
        let platformName: String
        let version: String?
    }

    enum ProductKind {
        case library
        case executable
        case plugin
    }

    struct PackageProduct: Decodable {
        let name: String
        let targets: [String]
        /// `{"library": ["automatic"]}`, `{"executable": null}`, `{"plugin": null}`.
        let type: [String: AnyDecodable?]

        var kind: ProductKind {
            if type.keys.contains("executable") { return .executable }
            if type.keys.contains("plugin") { return .plugin }
            return .library
        }
    }

    struct PackageTarget: Decodable {
        let name: String
        /// `regular`, `executable`, `test`, `system`, `binary`, `plugin`, `macro`.
        let type: String
        let path: String?
        let sources: [String]?
        let exclude: [String]
        let publicHeadersPath: String?
        var settings: [Setting]
        let resources: [Resource]
        var dependencies: [TargetDependency]
        /// The plugins the target asks to be run while it is built.
        let pluginUsages: [PluginUsage]
        /// A binary target's remote archive.
        let url: String?
        let checksum: String?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: AnyKey.self)
            name = try container.decode(String.self, forKey: AnyKey("name"))
            type = container.value(String.self, "type") ?? "regular"
            path = container.value(String.self, "path")
            sources = container.value([String].self, "sources")
            exclude = container.list(String.self, "exclude")
            publicHeadersPath = container.value(String.self, "publicHeadersPath")
            settings = container.list(Setting.self, "settings")
            resources = container.list(Resource.self, "resources")
            dependencies = container.list(TargetDependency.self, "dependencies")
            pluginUsages = container.list(PluginUsage.self, "pluginUsages")
            url = container.value(String.self, "url")
            checksum = container.value(String.self, "checksum")
        }
    }

    /// `{"plugin": ["SwiftLint", "SwiftLintPlugin"]}`: the plugin's name first,
    /// then the package it comes from, which is absent for one in the same
    /// package.
    struct PluginUsage: Decodable {
        let name: String
        let package: String?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: AnyKey.self)
            let values = container.value([String?].self, "plugin")
                ?? container.value([String?].self, "byName")
                ?? []

            name = values.first.flatMap { $0 } ?? ""
            package = values.count > 1 ? values[1] : nil
        }
    }

    /// `{"tool": "swift", "kind": {"define": {"_0": "FOO"}}}`
    struct Setting: Decodable {
        let tool: String
        let kind: [String: SettingValues]
        /// When the setting applies: the platforms it is limited to, and the
        /// traits that have to be on. Absent means always.
        let condition: SettingCondition?

        /// `define`, `headerSearchPath`, `defaultIsolation`…
        var name: String? {
            kind.keys.first
        }

        var values: [String] {
            kind.values.first?.values ?? []
        }

        /// Whether the setting is one this build uses.
        func applies(traits: Set<String>, platforms: Set<String>) -> Bool {
            condition?.applies(traits: traits, platforms: platforms) ?? true
        }
    }

    /// `{"platformNames": ["ios"], "traits": ["Fast"], "config": "debug"}`
    struct SettingCondition: Decodable {
        let platformNames: [String]
        let traits: [String]
        let config: String?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: AnyKey.self)
            platformNames = container.list(String.self, "platformNames")
            traits = container.list(String.self, "traits")
            config = container.value(String.self, "config")
        }
    }

    /// `{"_0": "FOO"}`, `{"_0": ["-Xfrontend", "-warn-long"]}` or `{}`.
    struct SettingValues: Decodable {
        let values: [String]

        init(from decoder: Decoder) throws {
            guard let container = try? decoder.container(keyedBy: AnyKey.self) else {
                values = []
                return
            }

            var result: [String] = []
            for key in container.allKeys.sorted(by: { $0.stringValue < $1.stringValue }) {
                if let value = try? container.decode(String.self, forKey: key) {
                    result.append(value)
                } else if let list = try? container.decode([String].self, forKey: key) {
                    result.append(contentsOf: list)
                }
            }
            values = result
        }
    }

    /// `{"rule": {"copy": {}}, "path": "Resources"}`
    struct Resource: Decodable {
        let path: String
        let rule: [String: AnyDecodable?]

        var isCopy: Bool {
            rule.keys.contains("copy")
        }

        /// `.embedInCode`: the file is not bundled at all, its bytes are a
        /// generated source the target compiles.
        var isEmbedInCode: Bool {
            rule.keys.contains("embedInCode")
        }
    }

    enum TargetDependencyKind {
        /// A target in the same package, or a product with the same name.
        case byName(String)
        /// A target in the same package.
        case target(String)
        /// `product: [productName, packageName, moduleAliases, condition]`
        case product(name: String, package: String?)
    }

    struct TargetDependency: Decodable {
        let kind: TargetDependencyKind
        /// The last element of the array a dependency is dumped as: the
        /// platforms it is limited to, and the traits that have to be on.
        let condition: SettingCondition?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: AnyKey.self)

            for key in container.allKeys {
                let values = container.list(DependencyElement.self, key.stringValue)
                let strings = values.compactMap(\.name)
                guard let name = strings.first else { continue }

                let kind: TargetDependencyKind
                switch key.stringValue {
                case "byName":
                    kind = .byName(name)
                case "target":
                    kind = .target(name)
                case "product":
                    kind = .product(name: name, package: strings.dropFirst().first)
                default:
                    continue
                }

                self.kind = kind
                condition = values.compactMap(\.condition).last
                return
            }

            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Unknown target dependency"))
        }

        /// Whether the dependency is one this build links.
        func applies(traits: Set<String>, platforms: Set<String>) -> Bool {
            condition?.applies(traits: traits, platforms: platforms) ?? true
        }
    }

    /// One element of the array a target dependency is dumped as: a name,
    /// `null`, the module aliases, or the condition.
    struct DependencyElement: Decodable {
        let name: String?
        let condition: SettingCondition?

        init(from decoder: Decoder) throws {
            if let single = try? decoder.singleValueContainer(),
               let name = try? single.decode(String.self)
            {
                self.name = name
                condition = nil
                return
            }

            name = nil
            /// Module aliases are a dictionary too, so a dictionary is only a
            /// condition when it names one of a condition's keys.
            guard
                let container = try? decoder.container(keyedBy: AnyKey.self),
                container.allKeys.contains(where: { Self.conditionKeys.contains($0.stringValue) })
            else {
                condition = nil
                return
            }

            condition = try? SettingCondition(from: decoder)
        }

        private static let conditionKeys: Set<String> = ["platformNames", "traits", "config"]
    }

    /// `{"fileSystem": [{...}]}` or `{"sourceControl": [{...}]}`
    struct Dependency: Decodable {
        let identity: String
        let name: String?
        let path: String?
        let url: String?
        /// The traits of that package this one turns on. Empty means the
        /// dependency's own defaults, which is what a dependency that says
        /// nothing gets.
        let traits: [String]

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: AnyKey.self)

            for key in container.allKeys {
                guard let entry = container.list(DependencyEntry.self, key.stringValue).first else { continue }

                identity = entry.identity
                name = entry.nameForTargetDependencyResolutionOnly
                path = entry.path
                url = entry.location?.url
                traits = (entry.traits ?? []).map(\.name)
                return
            }

            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Unknown package dependency"))
        }
    }

    struct DependencyEntry: Decodable {
        let identity: String
        let nameForTargetDependencyResolutionOnly: String?
        let path: String?
        let location: DependencyLocation?
        let traits: [Trait]?
    }

    /// `{"name": "Fast", "enabledTraits": []}`: one of a package's build-time
    /// options. The one named `default` is what a build that asks for nothing
    /// gets.
    struct Trait: Decodable {
        let name: String
        let enabledTraits: [String]

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: AnyKey.self)
            name = try container.decode(String.self, forKey: AnyKey("name"))
            enabledTraits = container.list(String.self, "enabledTraits")
        }
    }

    /// `{"remote": [{"urlString": "https://…"}]}`
    struct DependencyLocation: Decodable {
        let url: String?

        init(from decoder: Decoder) throws {
            guard let container = try? decoder.container(keyedBy: AnyKey.self) else {
                url = nil
                return
            }

            for key in container.allKeys {
                if let remote = container.list(DependencyRemote.self, key.stringValue).first {
                    url = remote.urlString
                    return
                }
            }
            url = nil
        }
    }

    struct DependencyRemote: Decodable {
        let urlString: String
    }

    /// The dump uses payload keys (`_0`) and wrapper keys (`byName`), so every
    /// container is keyed dynamically.
    struct AnyKey: CodingKey {
        let stringValue: String
        let intValue: Int? = nil

        init(_ value: String) { stringValue = value }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue _: Int) { nil }
    }
}

extension SwiftPM.SettingCondition {
    /// Whether what carries this condition is part of this build: a condition
    /// naming traits needs one of them on, and a condition naming platforms
    /// needs one of them built.
    ///
    /// `platforms` empty means the caller does not know which platforms the
    /// project builds, which still rules out the platforms Bazelize never
    /// builds for — Linux, Android, Windows and the rest are not what an Xcode
    /// project or an Apple toolchain produces.
    ///
    /// A configuration is not one of these: which configuration a rule is
    /// built in is decided when Bazel builds it, not when it is generated.
    func applies(traits: Set<String>, platforms: Set<String>) -> Bool {
        if !self.traits.isEmpty, self.traits.allSatisfy({ !traits.contains($0) }) {
            return false
        }

        let built = platforms.isEmpty ? Self.apple : platforms
        if !platformNames.isEmpty, platformNames.allSatisfy({ !built.contains($0) }) {
            return false
        }

        return true
    }

    /// The platforms an Apple toolchain builds, which is every platform that
    /// can reach a generated rule.
    private static let apple: Set<String> = [
        "macos", "maccatalyst", "ios", "tvos", "watchos", "visionos", "driverkit",
    ]
}

extension KeyedDecodingContainer where Key == SwiftPM.AnyKey {
    /// Absent, null and malformed all mean "not there": a manifest dump spans every
    /// tools version, and a key that does not apply is simply missing.
    func value<T: Decodable>(_ type: T.Type, _ key: String) -> T? {
        try? decodeIfPresent(type, forKey: SwiftPM.AnyKey(key))
    }

    func list<T: Decodable>(_: T.Type, _ key: String) -> [T] {
        (try? decodeIfPresent([T].self, forKey: SwiftPM.AnyKey(key))) ?? []
    }
}

// MARK: - AnyDecodable

/// Anything, decoded only to be ignored.
struct AnyDecodable: Decodable {
    let value: Any?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let value = try? container.decode(String.self) {
            self.value = value
        } else if let value = try? container.decode(Int.self) {
            self.value = value
        } else if let value = try? container.decode(Bool.self) {
            self.value = value
        } else {
            value = nil
        }
    }
}
