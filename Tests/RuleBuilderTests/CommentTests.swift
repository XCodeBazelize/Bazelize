//
//  CommentTests.swift
//  
//
//  Created by Yume on 2022/8/3.
//

@testable import RuleBuilder
import XCTest

final class CommentTests: XCTestCase {
    static let comment = Comment("test")
    func test() {
        XCTAssertEqual(Self.comment.text,        "# test")
        XCTAssertEqual(Self.comment.withComma,   "# test")
        XCTAssertEqual(Self.comment.withComment, "# test")
    }
}
