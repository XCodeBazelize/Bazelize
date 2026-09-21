import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros

/// `#stringify(1 + 1)` becomes `(1 + 1, "1 + 1")`.
struct StringifyMacro: ExpressionMacro {
    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in _: some MacroExpansionContext) throws -> ExprSyntax
    {
        guard let argument = node.arguments.first?.expression else {
            fatalError("#stringify takes one argument")
        }

        return "(\(argument), \(literal: argument.description))"
    }
}

@main
struct StringifyPlugin: CompilerPlugin {
    let providingMacros: [any Macro.Type] = [StringifyMacro.self]
}
