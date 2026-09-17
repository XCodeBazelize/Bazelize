//
//  ExampleTests.swift
//  ExampleTests
//
//  Created by Yume on 2023/1/7.
//

import LocalTarget1
import XCTest
@testable import Example

final class ExampleTests: XCTestCase {
    func testExample() throws {
        XCTAssertEqual(test(), 0b1111)
    }

    /// The local package declares a macro and expands it in its own sources, so
    /// the value only exists if the compiler loaded the generated plugin.
    func testPackageMacroExpands() throws {
        XCTAssertEqual(LocalTarget1.stringified.0, 2)
        XCTAssertEqual(LocalTarget1.stringified.1, "1 + 1")
    }
}
