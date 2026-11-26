import BazelRules
import Starlark
import Testing
@testable import BazelizeKit

// MARK: - CodeBuilderTests

struct CodeBuilderTests {
    @Test
    func ruleCallBringsItsLoadOnce() {
        let builder = CodeBuilder()
        builder.call(Rules.Swift.Call.swift_library(name: "A", srcs: ["A.swift"]))
        builder.call(Rules.Swift.Call.swift_library(name: "B", srcs: ["B.swift"]))
        builder.call(Rules.Builtin.Call.alias(name: "C", actual: .named(":A")))

        let output = builder.build()
        let loads = output.split(separator: "\n").filter { $0.hasPrefix("load(") }

        #expect(loads == [#"load("\#(Rules.Swift.swift_library.module)", "swift_library")"#])
    }
}
