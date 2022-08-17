//
//  NoneTests.swift
//
//
//  Created by Yume on 2022/8/17.
//

import XCTest
@testable import RuleBuilder

final class NoneTests: XCTestCase {
    static let none: StarlarkNone = nil

    func test() {
        XCTAssertEqual(Self.none.text, "None")
        XCTAssertEqual(Self.none.withComma, "None,")
        XCTAssertEqual(Self.none.withComment, "# None")
    }
}
