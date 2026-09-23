import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros

/// `#shout("hi")` becomes `"HI"`, which nothing but an expansion produces.
struct ShoutMacro: ExpressionMacro {
    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in _: some MacroExpansionContext) throws -> ExprSyntax
    {
        guard
            let argument = node.arguments.first?.expression,
            let literal = argument.as(StringLiteralExprSyntax.self)?.representedLiteralValue
        else {
            fatalError("#shout takes one string literal")
        }

        return "\(literal: literal.uppercased())"
    }
}

@main
struct ProviderPlugin: CompilerPlugin {
    let providingMacros: [any Macro.Type] = [ShoutMacro.self]
}
