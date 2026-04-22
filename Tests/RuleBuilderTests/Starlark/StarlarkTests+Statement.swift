import XCTest
@testable import RuleBuilder

extension StarlarkTests {
    func testCommentStatement() {
        let statement: Starlark.Statement = .comment("test")
        XCTAssertEqual(statement.text, "# test")
    }

    func testLoadStatement() {
        let statement: Starlark.Statement = .load(
            .init(
                module: "@build_bazel_rules_swift//swift:swift.bzl",
                symbols: [
                "swift_library",
                "swift_binary",
                .init("swift_common", as: "common"),
                ]
            )
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
        let symbol: Starlark.Statement.LoadSymbol = "swift_library"
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
