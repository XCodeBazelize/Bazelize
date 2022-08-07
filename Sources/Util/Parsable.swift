//
//  Parsable.swift
//
//
//  Created by Yume on 2022/4/26.
//

import Foundation
import PathKit
import Yams

// MARK: - Parsable

public protocol Parsable: Decodable {
    static func parse(_ path: Path) throws -> Self
    static func parse(_ content: String) throws -> Self
    static func parse(_ content: Foundation.Data) throws -> Self
}

extension Parsable {
    public static func parse(_ path: Path) throws -> Self {
        try parse(path.read())
    }

    public static func parse(_ content: String) throws -> Self {
        let data = Data(content.utf8)
        return try parse(data)
    }
}

// MARK: - JSONParsable

public protocol JSONParsable: Parsable { }
extension JSONParsable {
    public static func parse(_ content: Data) throws -> Self {
        let decoder = JSONDecoder()
        return try decoder.decode(Self.self, from: content)
    }
}

// MARK: - YamlParsable

public protocol YamlParsable: Parsable { }
extension YamlParsable {
    public static func parse(_ content: Data) throws -> Self {
        let decoder = YAMLDecoder()
        return try decoder.decode(Self.self, from: content)
    }
}
