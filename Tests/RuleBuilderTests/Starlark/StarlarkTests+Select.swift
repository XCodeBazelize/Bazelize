import Testing
@testable import RuleBuilder

extension StarlarkTests {
    @Test
    func testSelectSame() {
        let code = Starlark.Select.same("test").starlark
        #expect(code.text == "\"test\"")
    }

    @Test
    func testSelectVarious() {
        let code = Starlark.Select.various([
            .config("Release"): "r",
            .config("Debug"): "d",
        ]).starlark

        #expect(code.text == """
        select({
            "//:Debug": "d",
            "//:Release": "r"
        })
        """)
    }

    @Test
    func testSelectWithDefaultLabel() {
        let code: Starlark.Value = .select(
            .various([
                .config("Debug"): "d",
                .default: "fallback",
            ])
        )

        #expect(code.text == """
        select({
            "//:Debug": "d",
            "//conditions:default": "fallback"
        })
        """)
    }
}
