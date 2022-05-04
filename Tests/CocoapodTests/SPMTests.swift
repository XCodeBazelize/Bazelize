//
//  File.swift
//  
//
//  Created by Yume on 2022/4/25.
//

import Foundation
import XCTest
@testable import Cocoapod

final class SPMTests: XCTestCase {
    private static let sourceFile: URL = URL(fileURLWithPath: #file)
        .deletingLastPathComponent()
        .appendingPathComponent("Resource")

    private static func resource(_ file: String) -> String {
        return sourceFile.appendingPathComponent(file).path
    }
    
    private static func strings(_ file: String) throws -> String {
        return try String(contentsOfFile: resource(file), encoding: .utf8)
    }
    
}
