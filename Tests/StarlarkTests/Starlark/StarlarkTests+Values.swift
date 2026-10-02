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
            "c": "ccc",
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

    /// A value carrying a quote or a backslash is what Xcode hands over — a
    /// preprocessor definition spells one `ID=@"com.example"` — and a file that
    /// repeats it unescaped does not parse.
    @Test
    func testQuotingSurvivesEveryWayAValueIsMade() {
        let quoted = #"ID=@"com.example""#
        let escaped = #""ID=@\"com.example\"""#

        #expect(Starlark.Value.string(quoted).text == escaped)
        #expect(Starlark.Value(quoted)?.text == escaped)
        #expect(Starlark.Value([quoted])?.text.contains(escaped) == true)
        #expect([quoted].starlark?.text.contains(escaped) == true)
        #expect(Starlark.Value(["key": quoted])?.text.contains(escaped) == true)
    }

    @Test
    func testQuotingEscapesABackslashAndADictionaryKey() {
        #expect(Starlark.Value.string(#"a\b"#).text == #""a\\b""#)
        #expect(Starlark.Value([#"a"b"#: "c"])?.text.contains(#""a\"b": "c","#) == true)
    }

    /// An attribute given an empty list was given nothing: it reads as `None`
    /// the way every other empty attribute does, rather than as an empty list
    /// that someone decided on.
    @Test
    func testEmptyCollectionsAreNothing() {
        #expect(Starlark.Value.array([]).isEmptyValue)
        #expect(Starlark.Value.array([.none, .array([])]).isEmptyValue)
        #expect(Starlark.Value.dictionary([:]).isEmptyValue)
        #expect(!Starlark.Value.array([.string("a")]).isEmptyValue)

        let call = Starlark.Statement.Call("rule") {
            "deps" => [Starlark.Label]()
            "srcs" => ["a.swift"]
        }

        #expect(
            call.text
                == """
                rule(
                    # deps = None,
                    srcs = [
                        "a.swift",
                    ],
                )
                """)
    }
}
