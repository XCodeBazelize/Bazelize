//
//  SPMParser.swift
//
//
//  Created by Yume on 2023/1/19.
//

import Foundation

import Basics
import PathKit
import TSCBasic
import Workspace

enum SPMParser {
    static func parse(path: String) throws -> (products: [String: [String]], targets: [String]) {
        let packagePath = try AbsolutePath(validating: path)
        let observability = ObservabilitySystem { _,_ in }

        let workspace = try Workspace(forRootPackage: packagePath)
        let manifest = try tsc_await {
            workspace.loadRootManifest(
                at: packagePath,
                observabilityScope: observability.topScope,
                completion: $0)
        }

        let pair = manifest.products.map { ($0.name, $0.targets) }
        let products = Dictionary(pair, uniquingKeysWith: { first, _ in first })
        let targets = manifest.targets.map { $0.name }

        let productsDetail = products.map { key, value in
            """
            \(key):
            \(value.withNewLine.indent(1))
            """.indent(2)
        }.sorted().withNewLine

        print("""
        Find Local SPM
            at: \(path)
            products:
        \(productsDetail)
        """)

        return (products, targets)
    }
}
