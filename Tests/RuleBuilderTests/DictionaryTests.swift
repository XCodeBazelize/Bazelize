//
//  DictionaryTests.swift
//
//
//  Created by Yume on 2022/8/9.
//

import XCTest
@testable import RuleBuilder

final class DictionaryTests: XCTestCase {
    static let dictionary = Dictionary([
        "b": "bbb",
        "a": "aaa",
        "c": "ccc",
    ])


    func test() {
        let result = """
        {
            "a": "aaa",
            "b": "bbb",
            "c": "ccc"
        }
        """
        XCTAssertEqual(Self.dictionary.text, result)
    }
}
