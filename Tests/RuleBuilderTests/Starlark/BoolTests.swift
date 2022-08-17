//
//  BoolTests.swift
//
//
//  Created by Yume on 2022/8/17.
//

import XCTest
@testable import RuleBuilder

final class BoolTests: XCTestCase {
    static let yes: StarlarkBool = true
    static let no: StarlarkBool = false

    func test() {
        XCTAssertEqual(Self.yes.text, "True")
        XCTAssertEqual(Self.yes.withComma, "True,")
        XCTAssertEqual(Self.yes.withComment, "# True")

        XCTAssertEqual(Self.no.text, "False")
        XCTAssertEqual(Self.no.withComma, "False,")
        XCTAssertEqual(Self.no.withComment, "# False")
    }
}
