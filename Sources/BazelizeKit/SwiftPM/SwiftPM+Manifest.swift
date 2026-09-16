//
//  SwiftPM+Manifest.swift
//
//
//  The subset of `swift package dump-package` the generator needs.
//

import Foundation

// MARK: - SwiftPM

/// Generating Bazel rules for the Swift packages a project depends on.
public enum SwiftPM {}

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
        let targets: [PackageTarget]
        let dependencies: [Dependency]

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: AnyKey.self)
            name = try container.decode(String.self, forKey: AnyKey("name"))
            platforms = container.list(Platform.self, "platforms")
            products = container.list(PackageProduct.self, "products")
            targets = container.list(PackageTarget.self, "targets")
            dependencies = container.list(Dependency.self, "dependencies")
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
        let settings: [Setting]
        let resources: [Resource]
        let dependencies: [TargetDependency]
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
            url = container.value(String.self, "url")
            checksum = container.value(String.self, "checksum")
        }
    }

    /// `{"tool": "swift", "kind": {"define": {"_0": "FOO"}}}`
    struct Setting: Decodable {
        let tool: String
        let kind: [String: SettingValues]

        /// `define`, `headerSearchPath`, `defaultIsolation`…
        var name: String? {
            kind.keys.first
        }

        var values: [String] {
            kind.values.first?.values ?? []
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

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: AnyKey.self)

            for key in container.allKeys {
                let values = container.list(AnyDecodable.self, key.stringValue)
                let strings = values.compactMap { $0.value as? String }
                guard let name = strings.first else { continue }

                switch key.stringValue {
                case "byName":
                    kind = .byName(name)
                    return
                case "target":
                    kind = .target(name)
                    return
                case "product":
                    kind = .product(name: name, package: strings.dropFirst().first)
                    return
                default:
                    continue
                }
            }

            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Unknown target dependency"))
        }
    }

    /// `{"fileSystem": [{...}]}` or `{"sourceControl": [{...}]}`
    struct Dependency: Decodable {
        let identity: String
        let name: String?
        let path: String?
        let url: String?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: AnyKey.self)

            for key in container.allKeys {
                guard let entry = container.list(DependencyEntry.self, key.stringValue).first else { continue }

                identity = entry.identity
                name = entry.nameForTargetDependencyResolutionOnly
                path = entry.path
                url = entry.location?.url
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

extension KeyedDecodingContainer where Key == SwiftPM.AnyKey {
    /// Absent, null and malformed all mean "not there": a manifest dump spans every
    /// tools version, and a key that does not apply is simply missing.
    func value<T: Decodable>(_ type: T.Type, _ key: String) -> T? {
        try? decodeIfPresent(type, forKey: SwiftPM.AnyKey(key))
    }

    func list<T: Decodable>(_ type: T.Type, _ key: String) -> [T] {
        (try? decodeIfPresent([T].self, forKey: SwiftPM.AnyKey(key))) ?? []
    }
}

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
            self.value = nil
        }
    }
}
