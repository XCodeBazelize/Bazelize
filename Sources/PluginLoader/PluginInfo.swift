//
//  PluginInfo.swift
//
//
//  Created by Yume on 2022/8/24.
//

import Foundation
import PathKit
import PluginInterface
import Util

let swift = "5.6"

// MARK: - PluginInfo

struct PluginInfo: Codable {
    let repo: String
    let tag: String
    let libs: [String]


    var url: String {
        "https://github.com/\(repo)"
    }

    var user_repo: String {
        repo.replacingOccurrences(of: "/", with: "_")
    }

    /// libPluginA.dylib
    var libsName: [String] {
        libs.map { lib in
            "lib\(lib).dylib"
        }
    }

    var paths: [String] {
        libsName.map { lib in
            repo + "/" + lib
        }
    }
}

// MARK: - Array + Parsable

extension Array: Parsable where Element: Codable { }

// MARK: - Array + YamlParsable

extension Array: YamlParsable where Element: Codable { }

func parseManifest(_ path: Path) throws -> [PluginInfo] {
    try [PluginInfo].parse(path)
}
