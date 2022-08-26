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
        let code = build {
            Starlark.comment("test")
        }.text

        XCTAssertEqual(code, "# test")
    }

    func testLabel() {
        let code = build {
            "test"
        }.text

        XCTAssertEqual(code, "\"test\"")
    }

    func testNilString() {
        let nilString: String? = nil
        let code = build {
            nilString
        }.text

        XCTAssertEqual(code, "None")
    }

    func testTrue() {
        let code = build {
            true
        }.text

        XCTAssertEqual(code, "True")
    }

    func testFalse() {
        let code = build {
            false
        }.text

        XCTAssertEqual(code, "False")
    }

    func testDictionary() {
        let code = build {
            [
                "b": "bbb",
                "a": "aaa",
                "c": "ccc",
            ]
        }.text

        let result = """
        {
            "a": "aaa",
            "b": "bbb",
            "c": "ccc"
        }
        """
        XCTAssertEqual(code, result)
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
        let code = build {
            Starlark.Select.same("test")
        }.text

        XCTAssertEqual(code, "\"test\"")
    }

    func testSelectVarious() {
        let code = build {
            Starlark.Select.various([
                "Release": "r",
                "Debug": "d",
            ])
        }.text

        XCTAssertEqual(code, """
        select({
            "//:Debug": "d",
            "//:Release": "r"
        })
        """)
    }
}
