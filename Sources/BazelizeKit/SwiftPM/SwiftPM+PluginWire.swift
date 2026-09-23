//
//  SwiftPM+PluginWire.swift
//
//
//  The messages a build tool plugin and its host exchange.
//

import Foundation

// MARK: - SwiftPM.PluginWire

extension SwiftPM {
    /// What the host sends a plugin and what it says back.
    ///
    /// A plugin is a program that speaks one protocol: length-prefixed JSON over
    /// its standard input and output, carrying enums SwiftPM declares in
    /// `PluginMessages.swift`. Only the part a build tool plugin uses is
    /// mirrored here — the package graph it is given, and the commands it
    /// answers with.
    ///
    /// The protocol belongs to the toolchain, so a message that cannot be
    /// decoded is reported as exactly that rather than read as an absent
    /// command.
    enum PluginWire {
        /// A path, as the wire spells it: a subpath of another path, so a graph
        /// of files repeats no directory.
        struct URLNode: Encodable {
            let baseURLId: Int?
            let subpath: String
        }

        struct Tool: Encodable {
            let path: Int
            let triples: [String]?
        }

        struct File: Encodable {
            let basePathId: Int
            let name: String
            let type: String
        }

        struct Target: Encodable {
            let name: String
            let directoryId: Int
            let dependencies: [Dependency]
            let info: TargetInfo

            enum Dependency: Encodable {
                case target(Int)
                case product(Int)

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: AnyKey.self)
                    switch self {
                    case .target(let id):
                        try container.encode(["targetId": id], forKey: AnyKey("target"))
                    case .product(let id):
                        try container.encode(["productId": id], forKey: AnyKey("product"))
                    }
                }
            }
        }

        /// What the plugin is told a target is made of.
        ///
        /// Only the kinds a package can hold are spelled out; the shape of each
        /// is SwiftPM's, down to the key names.
        enum TargetInfo: Encodable {
            case swift(module: String, kind: String, sources: [File])
            case clang(module: String, kind: String, sources: [File], publicHeadersDirId: Int?)
            case binary(artifactId: Int)
            case system

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: AnyKey.self)
                switch self {
                case .swift(let module, let kind, let sources):
                    try container.encode(
                        SwiftInfo(
                            moduleName: module,
                            kind: kind,
                            sourceFiles: sources,
                            compilationConditions: [],
                            linkedLibraries: [],
                            linkedFrameworks: []),
                        forKey: AnyKey("swiftSourceModuleInfo"))
                case .clang(let module, let kind, let sources, let headers):
                    try container.encode(
                        ClangInfo(
                            moduleName: module,
                            kind: kind,
                            sourceFiles: sources,
                            preprocessorDefinitions: [],
                            headerSearchPaths: [],
                            publicHeadersDirId: headers,
                            linkedLibraries: [],
                            linkedFrameworks: []),
                        forKey: AnyKey("clangSourceModuleInfo"))
                case .binary(let artifact):
                    try container.encode(
                        BinaryInfo(
                            kind: ["xcframework": Empty()],
                            origin: ["local": Empty()],
                            artifactId: artifact),
                        forKey: AnyKey("binaryArtifactInfo"))
                case .system:
                    try container.encode(
                        SystemInfo(pkgConfig: nil, compilerFlags: [], linkerFlags: []),
                        forKey: AnyKey("systemLibraryInfo"))
                }
            }

            private struct SwiftInfo: Encodable {
                let moduleName: String
                let kind: String
                let sourceFiles: [File]
                let compilationConditions: [String]
                let linkedLibraries: [String]
                let linkedFrameworks: [String]
            }

            private struct ClangInfo: Encodable {
                let moduleName: String
                let kind: String
                let sourceFiles: [File]
                let preprocessorDefinitions: [String]
                let headerSearchPaths: [String]
                let publicHeadersDirId: Int?
                let linkedLibraries: [String]
                let linkedFrameworks: [String]
            }

            private struct BinaryInfo: Encodable {
                let kind: [String: Empty]
                let origin: [String: Empty]
                let artifactId: Int
            }

            private struct SystemInfo: Encodable {
                let pkgConfig: String?
                let compilerFlags: [String]
                let linkerFlags: [String]
            }

            private struct Empty: Encodable {}
        }

        struct Product: Encodable {
            let name: String
            let targetIds: [Int]
            let info: Info

            enum Info: Encodable {
                case executable(mainTargetId: Int)
                case library

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: AnyKey.self)
                    switch self {
                    case .executable(let main):
                        try container.encode(["mainTargetId": main], forKey: AnyKey("executable"))
                    case .library:
                        try container.encode(
                            ["kind": ["automatic": [String: String]()]],
                            forKey: AnyKey("library"))
                    }
                }
            }
        }

        struct Package: Encodable {
            let identity: String
            let displayName: String
            let directoryId: Int
            let origin: Origin
            let toolsVersion: ToolsVersion
            let dependencies: [Dependency]
            let productIds: [Int]
            let targetIds: [Int]

            struct ToolsVersion: Encodable {
                let major: Int
                let minor: Int
                let patch: Int
            }

            struct Dependency: Encodable {
                let packageId: Int
            }

            /// Where the package came from. A plugin can ask, and one that does
            /// is told the truth: the package under the tool is the root, one in
            /// the project's own repository is local, the rest are checkouts.
            enum Origin: Encodable {
                case root
                case local(pathId: Int)
                case repository(url: String, displayVersion: String, revision: String)

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: AnyKey.self)
                    switch self {
                    case .root:
                        try container.encode([String: String](), forKey: AnyKey("root"))
                    case .local(let path):
                        try container.encode(["path": path], forKey: AnyKey("local"))
                    case .repository(let url, let version, let revision):
                        try container.encode(
                            [
                                "url": url,
                                "displayVersion": version,
                                "scmRevision": revision,
                            ],
                            forKey: AnyKey("repository"))
                    }
                }
            }
        }

        /// The whole graph, as one message's worth of it.
        struct InputContext: Encodable {
            let paths: [URLNode]
            let targets: [Target]
            let products: [Product]
            let packages: [Package]
            let xcodeTargets: [String]
            let xcodeProjects: [String]
            let pluginWorkDirId: Int
            let toolSearchDirIds: [Int]
            let accessibleTools: [String: Tool]
        }

        /// `createBuildToolCommands`, the only thing the host asks of a build
        /// tool plugin.
        struct Request: Encodable {
            let context: InputContext
            let rootPackageId: Int
            let targetId: Int
            let pluginGeneratedSources: [Int]
            let pluginGeneratedResources: [Int]

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: AnyKey.self)
                try container.encode(Body(self), forKey: AnyKey("createBuildToolCommands"))
            }

            private struct Body: Encodable {
                let context: InputContext
                let rootPackageId: Int
                let targetId: Int
                let pluginGeneratedSources: [Int]
                let pluginGeneratedResources: [Int]

                init(_ request: Request) {
                    context = request.context
                    rootPackageId = request.rootPackageId
                    targetId = request.targetId
                    pluginGeneratedSources = request.pluginGeneratedSources
                    pluginGeneratedResources = request.pluginGeneratedResources
                }
            }
        }
    }
}

// MARK: - SwiftPM.PluginError

extension SwiftPM {
    enum PluginError: Error, CustomStringConvertible {
        /// The toolchain's protocol is not the one mirrored here.
        case undecodable(String)
        case runFailed(String)

        var description: String {
            switch self {
            case .undecodable(let reason):
                return "the plugin protocol of this toolchain is not the one bazelize speaks: \(reason)"
            case .runFailed(let reason):
                return "\(reason)"
            }
        }
    }
}
