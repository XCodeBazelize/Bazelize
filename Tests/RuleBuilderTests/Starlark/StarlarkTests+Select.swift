import XCTest
@testable import RuleBuilder

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
        let code: Starlark.Value = .select(
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
