//
//  Plugin+SwiftPM+Facade.swift
//
//
//  One label shape for every Swift package product, whatever generates it.
//

import Foundation
import PathKit
import Util

extension PluginSwiftPM {
    /// Every package product a target links reaches it through `//Packages`, not
    /// through the repository whatever tool generated it happens to use.
    ///
    /// The generated rules behind a product are an implementation detail: today
    /// rules_swift_package_manager produces them in an external repository, and the
    /// facade is an `alias` pointing there. Replacing that with rules bazelize
    /// generates itself is then a change to `Packages/` alone — no target's `deps`
    /// mention a package repository, so none of them move.
    static let packagesDirectory = "Packages"

    /// A product a target links: which package it belongs to, and the rule that
    /// implements it today.
    struct FacadeProduct {
        let package: String
        let product: String
        let actual: String
    }

    /// `//Packages/SFSafeSymbols:SFSafeSymbols`
    func facadeLabel(package: String, product: String) -> String {
        "//\(Self.packagesDirectory)/\(package):\(product)"
    }

    /// One `BUILD` per package, aliasing each product a target actually links.
    var facadeFiles: [PluginBuiltin.Custom] {
        let grouped = Dictionary(grouping: facadeProducts) { product in
            product.package
        }

        return grouped.keys.sorted().compactMap { package -> PluginBuiltin.Custom? in
            guard let products = grouped[package] else { return nil }

            var seen = Set<String>()
            let aliases = products
                .sorted { $0.product < $1.product }
                .filter { seen.insert($0.product).inserted }
                .map { product in
                    """
                    alias(
                        name = "\(product.product)",
                        actual = "\(product.actual)",
                        visibility = ["//visibility:public"],
                    )
                    """
                }

            return .init(
                path: "\(Self.packagesDirectory)/\(package)/BUILD",
                content: ([Self.facadeHeader] + aliases).joined(separator: "\n") + "\n")
        }
    }

    // MARK: Private

    private static let facadeHeader = """
    # Generated using Bazelize
    #
    # The rules behind a package product live elsewhere; a target depends on the
    # product, never on where it is generated.

    """

    /// The products every target links, with the package they belong to and the
    /// rule that currently implements them.
    private var facadeProducts: [FacadeProduct] {
        kit.project.targets
            .flatMap(\.dependencies.packageProducts)
            .compactMap(facadeProduct)
    }
}
