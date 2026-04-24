import Testing
@testable import RuleBuilder

extension StarlarkTests {
    @Test
    func testCommentStatement() {
        let statement: Starlark.Statement = .comment(.init("test"))
        #expect(statement.text == "# test")
    }

    @Test
    func testLoadStatement() {
        let statement: Starlark.Statement = .load(
            .init(
                module: "@build_bazel_rules_swift//swift:swift.bzl",
                symbols: [
                    "swift_library",
                    "swift_binary",
                    .init("swift_common", as: "common"),
                ]))

        #expect(
            statement
                .text ==
                #"load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library", "swift_binary", common = "swift_common")"#)
    }

    @Test
    func testCallStatement() {
        let statement: Starlark.Statement = .call(
            .init("bazel_dep", [
                .named("name", "rules_swift"),
                .named("version", "3.5.0"),
            ]))

        #expect(statement.text == """
        bazel_dep(
            name = "rules_swift",
            version = "3.5.0",
        )
        """)
    }

    @Test
    func testLoadSymbolStringLiteral() {
        let symbol: Starlark.Statement.LoadSymbol = "swift_library"
        #expect(symbol.text == #""swift_library""#)
    }

    @Test
    func testLabelStringLiteral() {
        let label: Starlark.Label = "swift_library"
        #expect(label.text == #""swift_library""#)
    }

    @Test
    func testLabelDefault() {
        let label: Starlark.Label = .default
        #expect(label.text == #""//conditions:default""#)
    }

    @Test
    func testLabelConfig() {
        let label: Starlark.Label = .config("Debug")
        #expect(label.text == #""//:Debug""#)
    }

    @Test
    func testLabelNamed() {
        let label: Starlark.Label = .named("//foo:bar")
        #expect(label.text == #""//foo:bar""#)
    }
}
