import Testing
@testable import Starlark

extension StarlarkTests {
    @Test
    func testLabelString() {
        let code: Starlark.Value = "test"
        #expect(code.text == "\"test\"")
    }

    @Test
    func testLabel() {
        let code: Starlark.Value = .label("test")
        #expect(code.text == "\"test\"")
    }

    @Test
    func testTypedLabel() {
        let code: Starlark.Value = .label(.init("test"))
        #expect(code.text == "\"test\"")
    }

    @Test
    func testNil() {
        let code: Starlark.Value = nil
        #expect(code.text == "None")
    }

    @Test
    func testNilString() {
        let nilString: String? = nil
        let code: Starlark.Value = build {
            nilString
        }

        #expect(code.text == "None")
    }

    @Test
    func testTrue() {
        let code: Starlark.Value = true
        #expect(code.text == "True")
    }

    @Test
    func testFalse() {
        let code: Starlark.Value = false
        #expect(code.text == "False")
    }

    @Test
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
        #expect(code.text == result)
    }

    @Test
    func testArray() {
        let code: Starlark.Value = ["1", "2"]

        let result = """
        [
            "1",
            "2",
        ]
        """
        #expect(code.text == result)
    }

    @Test
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

        #expect(code == """
        [
            "1",
            "2",
            "3",
        ]
        """)
    }

    @Test
    func testArrayWithNilString2() {
        let nilString: String? = nil
        let code = build {
            nilString
            "1"
            "2"
            "3"
            nilString
        }.text

        #expect(code == """
        [
            "1",
            "2",
            "3",
        ]
        """)
    }
}
