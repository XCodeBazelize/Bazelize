//
//  StarlarkTests.swift
//
//
//  Created by Yume on 2022/8/18.
//

import XCTest
@testable import RuleBuilder

// MARK: - StarlarkTests

final class StarlarkTests: XCTestCase {
    func build(@StarlarkBuilder builder: () -> Starlark) -> Starlark {
        builder()
    }

    func testComment() {
        let code: Starlark = .comment("test")
        XCTAssertEqual(code.text, "# test")
    }

    func testLabelString() {
        let code: Starlark = "test"
        XCTAssertEqual(code.text, "\"test\"")
    }

    func testLabel() {
        let code: Starlark = .label("test")
        XCTAssertEqual(code.text, "\"test\"")
    }

    func testNil() {
        let code: Starlark = nil
        XCTAssertEqual(code.text, "None")
    }

    func testNilString() {
        let nilString: String? = nil
        let code: Starlark = build {
            nilString
        }

        XCTAssertEqual(code.text, "None")
    }

    func testTrue() {
        let code: Starlark = true
        XCTAssertEqual(code.text, "True")
    }

    func testFalse() {
        let code: Starlark = false
        XCTAssertEqual(code.text, "False")
    }

    func testDictionary() {
        let code: Starlark = [
            "b": "bbb",
            "a": "aaa",
            "c": "ccc",
        ]

        let result = """
        {
            "a": "aaa",
            "b": "bbb",
            "c": "ccc"
        }
        """
        XCTAssertEqual(code.text, result)
    }

    func testArray() {
        let code: Starlark = ["1", "2"]

        let result = """
        [
            "1",
            "2",
        ]
        """
        XCTAssertEqual(code.text, result)
    }

    func testArrayWithNilString() {
        let nilString: String? = nil
        let code = build {
            [
                nilString,
                "1",
                "2",
                "3",
                nilString,
            ]
        }.text

        XCTAssertEqual(code, """
        [
            "1",
            "2",
            "3",
        ]
        """)
    }

    func testArrayWithNilString2() {
        let nilString: String? = nil
        let code = build {
            nilString
            "1"
            "2"
            "3"
            nilString
        }.text

        XCTAssertEqual(code, """
        [
            "1",
            "2",
            "3",
        ]
        """)
    }
}

// MARK: Select
extension StarlarkTests {
    func testSelectSame() {
        let code = Starlark.Select.same("test").starlark
        XCTAssertEqual(code.text, "\"test\"")
    }

    func testSelectVarious() {
        let code = Starlark.Select.various([
            "Release": "r",
            "Debug": "d",
        ]).starlark

        XCTAssertEqual(code.text, """
        select({
            "//:Debug": "d",
            "//:Release": "r"
        })
        """)
    }
}
