import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// `#stringify(1 + 1)` expands to `(1 + 1, "1 + 1")`.
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
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
struct Local1MacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [StringifyMacro.self]
}
