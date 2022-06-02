//
//  XCodeSPM.swift
//
//
//  Created by Yume on 2022/4/25.
//

import Foundation
import PathKit
import XcodeProj

extension Array where Element == PBXNativeTarget {
    private var flatPackages: [Package] {
        self.flatMap(\.spm)
    }
    
    public var isHaveSPM: Bool {
        return !flatPackages.isEmpty
    }
    
    public var spm_pkgs: String {
        return flatPackages.spm_pkgs
    }
    
    public var spm_repositories: String {
        return """
        load("@cgrindel_rules_spm//spm:defs.bzl", "spm_pkg", "spm_repositories")
        
        spm_repositories(
            name = "swift_pkgs",
            dependencies = [
        \(spm_pkgs)
            ],
        )
        """
    }
}

extension Array where Element == Package {
    private var mapping: [String: (Package, Set<String>)] {
        var dict: [String: (Package, Set<String>)] = [:]
        for package in self {
            guard let url = package.product.package?.repositoryURL else {continue}
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

    private var spm_pkgs: String {
        return mapping.compactMap { _, value -> String? in
            let (package, set) = value
            return package.spm_pkg(set)
        }.joined(separator: "\n")
    }
}

#warning("TODO local spm")
// path    A local path string to the package repository.    None
// name    Optional. The name (string) to be used for the package in Package.swift.    None
private struct Package {
    let product: XCSwiftPackageProductDependency

    /// exact_version    Optional. A string representing a valid "exact" SPM version.    None
    /// from_version    Optional. A string representing a valid "from" SPM version.    None
    /// revision    Optional. A commit hash (string).    None
    var version: String? {
        switch product.package?.versionRequirement {
        case let .exact(ver):
            return """
            exact_version = "\(ver)"
            """
        case let .range(from, _): fallthrough
        case let .upToNextMajorVersion(from): fallthrough
        case let .upToNextMinorVersion(from):
            return """
            from_version = "\(from)"
            """
        case let .revision(commit):
            return """
            revision = "\(commit)"
            """
        case .branch: fallthrough
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
    func spm_pkg(_ set: Set<String>) -> String? {
        guard let url = product.package?.repositoryURL else { return nil }
        guard let version = version else { return nil }
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

    /// "@swift_pkgs//swift-log:Logging",
    var dep: String? {
        /// https://github.com/apple/swift-log.git
        guard let url = product.package?.repositoryURL else { return nil }
        let path = Path(url)
        /// swift-log
        let repo = path.lastComponentWithoutExtension

        /// Logging
        let product = self.product.productName

        return """
                "@swift_pkgs//\(repo):\(product)",
        """
    }
}

extension PBXNativeTarget {
    private var _spm: [XCSwiftPackageProductDependency] {
        return (try? frameworksBuildPhase()?.files?.compactMap(\.product)) ?? []
    }

    fileprivate var spm: [Package] {
        _spm.map(Package.init)
    }
    
    public var spm_deps: [String] {
        return spm.compactMap(\.dep)
    }
}
