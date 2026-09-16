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
    /// Every package product a target links reaches it through `//Packages`, the
    /// one directory the package rules are generated into.
    static let packagesDirectory = "Packages"

    /// A product a target links, and the package it belongs to.
    struct FacadeProduct {
        let package: String
        let product: String
    }

    /// `//Packages/SFSafeSymbols:SFSafeSymbols`
    func facadeLabel(package: String, product: String) -> String {
        "//\(Self.packagesDirectory)/\(package):\(product)"
    }
}
