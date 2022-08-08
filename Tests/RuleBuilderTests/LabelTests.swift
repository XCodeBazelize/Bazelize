//
//  LabelTests.swift
//  
//
//  Created by Yume on 2022/8/3.
//

@testable import RuleBuilder
import XCTest

final class LabelTests: XCTestCase {
    static let label: Label = "1"
    func test() {
        XCTAssertEqual(Self.label.text,        "\"1\"")
        XCTAssertEqual(Self.label.withComma,   "\"1\",")
        XCTAssertEqual(Self.label.withComment, "# \"1\"")
    }
}
