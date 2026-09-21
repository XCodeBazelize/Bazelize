import Foundation

typealias FlagType = String

// MARK: - Option Definition

/// A complete frontend option definition
struct OptionDefinition: Equatable {
    let name: String
    let type: OptionType
    let helpText: String
    let metaVarName: String?
    let aliasOf: String?
    let flags: Set<FlagType>
    let declaredInLetBlock: Bool
    let letBlockFlags: Set<FlagType>
    let otherOptions: [String]
    let otherGroup: [String]
    
    var allFlags: Set<FlagType> {
        flags.union(letBlockFlags)
    }
}

// MARK: - Parsing Context

class ParsingContext {
    var currentLetBlockFlags: Set<FlagType> = []
    var inLetBlock: Bool = false
}

// MARK: - Parser

enum ParserError: Error {
    case unexpectedToken(String)
    case invalidOptionType
    case invalidFlag
    case missingParameter
    case syntaxError(String)
}

class Parser {
    private let lexer: Lexer
    private var currentToken: Token
    private let context: ParsingContext
    
    init(input: String) {
        self.lexer = Lexer(input: input)
        self.currentToken = self.lexer.nextToken()
        self.context = ParsingContext()
    }
    
    private func advance() {
        currentToken = lexer.nextToken()
    }
    
    private func matchIf(_ expected: Token) {
        guard currentToken == expected else {
            return
        }
        advance()
    }
    
    private func match(_ expected: Token) throws {
        guard currentToken == expected else {
            throw ParserError.unexpectedToken("Expected \(expected), got \(currentToken)")
        }
        advance()
    }
    
    @discardableResult
    private func skipUtil(_ expected: Token) -> String {
        var text = ""
        while currentToken != expected && currentToken != .eof {
            text += currentToken.text
            advance()
        }
        return text
    }
    
    public func parseOptionDefinitions() throws -> [OptionDefinition] {
        var definitions: [OptionDefinition] = []
        
        while currentToken != .eof {
            switch currentToken {
            case .let:
                let blockDefinitions = try parseLetBlock()
                definitions += blockDefinitions
            case .def:
                if let definition = try parseOptionDefinition() {
                    definitions.append(definition)
                }
            case .class:
                parseClass()
            default:
                advance()
            }
        }
        
        return definitions
    }
    
    /// let Flags = [FrontendOption, NoDriverOption, HelpHidden, ModuleInterfaceOptionIgnorable] in {}
    private func parseLetBlock() throws -> [OptionDefinition] {
        var definitions: [OptionDefinition] = []
        
        // let 'Flags'
        try match(.let)
        _ = try parseIdentifier()

        try match(.equals)
        let flags = try parseFlags()
        let origin = context.currentLetBlockFlags
        context.currentLetBlockFlags = flags
        
        try match(.in)
        try match(.leftBrace)
        
        context.inLetBlock = true
        
        while currentToken != .rightBrace && currentToken != .eof {
            if case .def = currentToken {
                if let definition = try parseOptionDefinition() {
                    // Store definitions if needed
                    definitions.append(definition)
                }
            }
            if case .let = currentToken {
                let blockDefinitions = try parseLetBlock()
                definitions += blockDefinitions
            }
        }
        
        context.inLetBlock = false
        
        if case .rightBrace = currentToken {
            advance()
        }
        
        context.currentLetBlockFlags = origin
        return definitions
    }
    
    /// Flags<[FrontendOption, HelpHidden]>
    private func parseFlags() throws -> Set<FlagType> {
        var flags: Set<FlagType> = []
        
        try match(.leftBracket)
        
        while currentToken != .rightBracket {
            if case .identifier(let flagName) = currentToken {
                flags.insert(flagName)
            }
            advance()
            
            matchIf(.comma)
        }
        
        try match(.rightBracket)
        return flags
    }
    
    private func parseStringArray() throws -> [String] {
        var strings: [String] = []
        try match(.leftBracket)
        while currentToken != .rightBracket {
            let string = try parseString()
            strings.append(string)
            
            matchIf(.comma)
        }
        try match(.rightBracket)
        return strings
    }
    
    /// Flag<["-"], "help">
    private func parseOptionType(_ typeString: String) throws -> OptionType {
        try match(.leftAngle)
        // FIXME: (@yume190) !!! -> prefixes
        let prefix: String = try parseStringArray().first!
        try match(.comma)
        let name = try parseString()
        
        var type: OptionType
        
        switch typeString {
        case "Flag":
            type = .flag(prefix: prefix, name: name)
        case "Joined":
            type = .joined(prefix: prefix, name: name)
        case "Separate":
            type = .separate(prefix: prefix, name: name)
        case "CommaJoined":
            type = .commaJoined(prefix: prefix, name: name)
        case "MultiArg":
            try match(.comma)
            guard case .number(let count) = currentToken else {
                throw ParserError.unexpectedToken("Expected number")
            }
            advance()
            type = .multiArg(prefix: prefix, name: name, count: count)
        case "JoinedOrSeparate":
            type = .joinedOrSeparate(prefix: prefix, name: name)
        case "JoinedAndSeparate":
            type = .joinedAndSeparate(prefix: prefix, name: name)
        default:
            throw ParserError.invalidOptionType
        }
        
        try match(.rightAngle)
        return type
    }
    
    /// skip class define
    ///
    /// class DebugCrashOpt : Group<debug_crash_Group>;
    /// class OptionKind<string name, int precedence = 0, bit sentinel = false> {}
    private func parseClass() {
        try? match(.class)
        _ = try? parseIdentifier()
        if case .colon = currentToken {
            skipUtil(.semicolon)
            matchIf(.semicolon)
        } else {
            skipUtil(.rightBracket)
            matchIf(.rightBracket)
        }
    }
    
    private func parseString() throws -> String {
        var text: String = ""
        if case .string(let value) = currentToken {
            text += value
            advance()
            while case .string(let value) = currentToken {
                text += value
                advance()
            }
        } else {
            throw ParserError.unexpectedToken("Expected string")
        }
        
        return text
    }
    
    private func parseIdentifier() throws -> String {
        if case .identifier(let value) = currentToken {
            advance()
            return value
        } else {
            throw ParserError.unexpectedToken("Expected Identifier")
        }
    }
    
    private func parseOptionDefinition() throws -> OptionDefinition? {
        try match(.def)
        let name = try parseIdentifier()
        try match(.colon)
        let typeString = try parseIdentifier()
        
        /// skip when no flag
        guard OptionType.contains(typeString) else {
            skipUtil(.semicolon)
            return nil
        }
        let type = try parseOptionType(typeString)
        var helpText = ""
        var otherOptions: [String] = []
        var otherGroup: [String] = []
        var metaVarName: String? = nil
        var aliasOf: String? = nil
        var flags: Set<FlagType> = []
        
        matchIf(.comma)
        
        while currentToken != .semicolon && currentToken != .eof {
            if case .identifier(let attr) = currentToken {
                advance() // Skip attr
                
                if currentToken == .leftAngle {
                    try match(.leftAngle)
                    
                    switch attr {
/// HelpText<"Triggers llvm fatal_error if typechecker tries to typecheck a decl "
///        "with the provided prefix name">;
                    case "HelpText":
                        helpText = try parseString()
                    /// MetaVarName<"<name>">
                    case "MetaVarName":
                        metaVarName = try parseString()
                    /// Alias<warn_long_function_bodies>
                    case "Alias":
                        aliasOf = try parseIdentifier()
                    case "Flags":
                        flags = try parseFlags()
                    default:
                        let group = "\(attr)<\(skipUtil(.rightAngle))>"
                        otherGroup.append(group)
                        break
                    }
                    
                    try match(.rightAngle)
                } else {
                    otherOptions.append(attr)
                    matchIf(.comma)
                }
            }
            
            matchIf(.comma)
        }
        
        try match(.semicolon)

        return OptionDefinition(
            name: name,
            type: type,
            helpText: helpText,
            metaVarName: metaVarName,
            aliasOf: aliasOf,
            flags: flags,
            declaredInLetBlock: context.inLetBlock,
            letBlockFlags: context.currentLetBlockFlags,
            otherOptions: otherOptions,
            otherGroup: otherGroup
        )
    }
}

class TableGenParser {
    static func parse(_ input: String) throws -> [OptionDefinition] {
        let parser = Parser(input: input)
        return try parser.parseOptionDefinitions()
    }
}
