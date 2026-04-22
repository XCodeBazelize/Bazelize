import XCTest
@testable import RuleBuilder

extension StarlarkTests {
    func testLabelString() {
        let code: Starlark.Value = "test"
        XCTAssertEqual(code.text, "\"test\"")
    }

    func testLabel() {
        let code: Starlark.Value = .label("test")
        XCTAssertEqual(code.text, "\"test\"")
    }

    func testTypedLabel() {
        let code: Starlark.Value = .label(.init("test"))
        XCTAssertEqual(code.text, "\"test\"")
    }

    func testNil() {
        let code: Starlark.Value = nil
        XCTAssertEqual(code.text, "None")
    }

    func testNilString() {
        let nilString: String? = nil
        let code: Starlark.Value = build {
            nilString
        }

        XCTAssertEqual(code.text, "None")
    }

    func testTrue() {
        let code: Starlark.Value = true
        XCTAssertEqual(code.text, "True")
    }

    func testFalse() {
        let code: Starlark.Value = false
        XCTAssertEqual(code.text, "False")
    }

    func testDictionary() {
        let code: Starlark.Value = [
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
        let code: Starlark.Value = ["1", "2"]

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
