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

    func testTypedLabel() {
        let code: Starlark = .label(.init("test"))
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
            .config("Release"): "r",
            .config("Debug"): "d",
        ]).starlark

        XCTAssertEqual(code.text, """
        select({
            "//:Debug": "d",
            "//:Release": "r"
        })
        """)
    }

    func testSelectWithDefaultLabel() {
        let code: Starlark = .select(
            .various([
                .config("Debug"): "d",
                .default: "fallback",
            ])
        )

        XCTAssertEqual(code.text, """
        select({
            "//:Debug": "d",
            "//conditions:default": "fallback"
        })
        """)
    }
}

// MARK: Statement
extension StarlarkTests {
    func testLoadStatement() {
        let statement: Starlark.Statement = .load(
            module: "@build_bazel_rules_swift//swift:swift.bzl",
            symbols: [
                "swift_library",
                "swift_binary",
                .init("swift_common", as: "common"),
            ]
        )

        XCTAssertEqual(
            statement.text,
            #"load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library", "swift_binary", common = "swift_common")"#
        )
    }

    func testCallStatement() {
        let statement: Starlark.Statement = .call(
            .init("bazel_dep", [
                .named("name", "rules_swift"),
                .named("version", "3.5.0"),
            ])
        )

        XCTAssertEqual(statement.text, """
        bazel_dep(
            name = "rules_swift",
            version = "3.5.0",
        )
        """)
    }

    func testLoadSymbolStringLiteral() {
        let symbol: Starlark.LoadSymbol = "swift_library"
        XCTAssertEqual(symbol.text, #""swift_library""#)
    }

    func testLabelStringLiteral() {
        let label: Starlark.Label = "swift_library"
        XCTAssertEqual(label.text, #""swift_library""#)
    }

    func testLabelDefault() {
        let label: Starlark.Label = .default
        XCTAssertEqual(label.text, #""//conditions:default""#)
    }

    func testLabelConfig() {
        let label: Starlark.Label = .config("Debug")
        XCTAssertEqual(label.text, #""//:Debug""#)
    }

    func testLabelNamed() {
        let label: Starlark.Label = .named("//foo:bar")
        XCTAssertEqual(label.text, #""//foo:bar""#)
    }
}
