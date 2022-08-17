//
//  CommentTests.swift
//
//
//  Created by Yume on 2022/8/3.
//

import XCTest
@testable import RuleBuilder

final class CommentTests: XCTestCase {
    static let comment = StarlarkComment("test")

    func test() {
        XCTAssertEqual(Self.comment.text, "# test")
        XCTAssertEqual(Self.comment.withComma, "# test")
        XCTAssertEqual(Self.comment.withComment, "# test")
    }
}
