//
//  Commands+PkgConfig.swift
//
//  Compiler and linker flags reported by pkg-config.
//

import Foundation

extension Commands.pkgConfig {
    public static func pkgConfigCFlags(package: String) async throws -> [String] {
        try await Commands.text("pkg-config", ["--cflags", package])
            .split(whereSeparator: \.isWhitespace).map(String.init)
    }

    public static func pkgConfigLinkerFlags(package: String) async throws -> [String] {
        try await Commands.text("pkg-config", ["--libs", package])
            .split(whereSeparator: \.isWhitespace).map(String.init)
    }
}
