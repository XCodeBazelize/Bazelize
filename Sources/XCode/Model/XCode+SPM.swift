//
//  XCodeSPM.swift
//
//
//  Created by Yume on 2022/4/25.
//

import Foundation
import PathKit
import Util
import XcodeProj

extension Array where Element == Target {
    // MARK: Public


    public var isHaveSPM: Bool {
        !flatPackages.isEmpty
    }


    public func spm_pkgs(_ path: Path? = nil) -> String {
        flatPackages.spm_pkgs(path)
    }

    public func spm_repositories(_ path: Path? = nil) -> String {
        """
        load("@cgrindel_rules_spm//spm:defs.bzl", "spm_pkg", "spm_repositories")

        spm_repositories(
            name = "swift_pkgs",
            dependencies = [
        \(spm_pkgs(path).indent(2))
            ],
        )
        """
    }

    // MARK: Private

    private var flatPackages: [Package] {
        flatMap(\.native.spm)
    }
}

extension Array where Element == Package {
    /// Target          -> Target.Name
    ///     Package     -> Target
    ///     Set<String> -> deps
    private var mapping: [String: (Package, Set<String>)] {
        var dict: [String: (Package, Set<String>)] = [:]
        for package in self {
            guard let url = package.product.package?.repositoryURL else { continue }
            if var (_, set) = dict[url] {
                set.insert(package.product.productName)
                dict[url] = (package, set)
            } else {
                let set = Set(arrayLiteral: package.product.productName)
                dict[url] = (package, set)
            }
        }

        return dict
    }

    private func spm_pkgs(_ path: Path? = nil) -> String {
        let resolved: Package.Resolved?
        if let projRoot = path {
            let resolvedPath = projRoot + "project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
            resolved = try? .parse(resolvedPath)
        } else {
            resolved = nil
        }

        return mapping.compactMap { _, value -> String? in
            let (package, set) = value
            return package.spm_pkg(set, resolved)
        }.withNewLine
    }
}

#warning("TODO local spm")

// MARK: - Package

// path    A local path string to the package repository.    None
// name    Optional. The name (string) to be used for the package in Package.swift.    None
private struct Package {
    /// xxx.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
    /// {
    ///   "pins" : [
    ///     {
    ///       "identity" : "alertkit",
    ///       "kind" : "remoteSourceControl",
    ///       "location" : "https://github.com/EhPanda-Team/AlertKit.git",
    ///       "state" : {
    ///         "branch" : "custom",
    ///         "revision" : "39b01c53ffadf3dab9871dd4c960cd81af5246b6"
    ///       }
    ///     },
    ///   "version" : 2
    /// }
    /// {
    ///   "object": {
    ///     "pins": [
    ///       {
    ///         "package": "Rainbow",
    ///         "repositoryURL": "https://github.com/onevcat/Rainbow",
    ///         "state": {
    ///           "branch": null,
    ///           "revision": "626c3d4b6b55354b4af3aa309f998fae9b31a3d9",
    ///           "version": "3.2.0"
    ///         }
    ///       },
    ///   "version" : 1
    /// }
    struct Resolved: JSONParsable {
        struct Object: Codable {
            let pins: [Pin1]
        }

        struct Pin1: Codable {
            /// Rainbow
            let package: String
            let state: State
        }

        struct Pin2: Codable {
            /// alertkit
            let identity: String
            let state: State
        }

        struct State: Codable {
            let revision: String
        }

        let version: Int
        let object: Object?
        let pins: [Pin2]?


        subscript(_ name: String) -> String? {
            switch version {
            case 1:
                return object?.pins.first { $0.package == name }?.state.revision
            case 2:
                return pins?.first { $0.identity == name.lowercased() }?.state.revision
            default:
                return nil
            }
        }
    }

    let product: XCSwiftPackageProductDependency

    /// "@swift_pkgs//swift-log:Logging",
    var dep: String? {
        /// https://github.com/apple/swift-log.git
        guard let url = product.package?.repositoryURL else { return nil }
        let path = Path(url)
        /// swift-log
        let repo = path.lastComponentWithoutExtension

        /// Logging
        let product = product.productName

        return """
            "@swift_pkgs//\(repo):\(product)",
            """
    }

    /// exact_version    Optional. A string representing a valid "exact" SPM version.    None
    /// from_version    Optional. A string representing a valid "from" SPM version.    None
    /// revision    Optional. A commit hash (string).    None
    func version(_ resolved: Resolved?) -> String? {
        switch product.package?.versionRequirement {
        case .exact(let ver):
            return """
                exact_version = "\(ver)"
                """
        case .range(let from, _): fallthrough
        case .upToNextMajorVersion(let from): fallthrough
        case .upToNextMinorVersion(let from):
            return """
                from_version = "\(from)"
                """
        case .revision(let commit):
            return """
                revision = "\(commit)"
                """
        case .branch(let branch):
            guard let commit = resolved?[product.package?.name ?? ""] else { return nil }
            return """
                # branch `\(branch)`
                revision = "\(commit)"
                """
        default: return nil
        }
    }


    /// spm_pkg(
    ///     "https://github.com/apple/swift-log.git",
    ///     exact_version = "1.4.2",
    ///     products = ["Logging"],
    /// ),
    ///
    /// url    A string representing the URL for the package repository.    None
    ///
    /// products    A list of string values representing the names of the products to be used.    []
    func spm_pkg(_ set: Set<String>, _ resolved: Package.Resolved?) -> String? {
        guard let url = product.package?.repositoryURL else { return nil }
        guard let version = version(resolved) else { return nil }
        let products = set.map { product in
            """
            "\(product)"
            """
        }.joined(separator: " ,")

        return """
            spm_pkg(
                "\(url)",
                \(version),
                products = [\(products)],
            ),
            """
    }
}

extension PBXNativeTarget {
    // MARK: Public


    /// use for `deps`
    public var spm_deps: String {
        spm
            .compactMap(\.dep)
            .withNewLine
    }

    // MARK: Fileprivate

    fileprivate var spm: [Package] {
        _spm.map(Package.init)
    }

    // MARK: Private

    private var _spm: [XCSwiftPackageProductDependency] {
        (try? frameworksBuildPhase()?.files?.compactMap(\.product)) ?? []
    }
}
