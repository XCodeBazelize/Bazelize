import Foundation

// MARK: - Lexical Analysis

enum Token: Equatable {
    case `class`
    case def
    case `let`
    case `in`
    case identifier(String)
    case string(String)
    case number(Int)
    case colon
    case semicolon
    case comma
    case equals
    case leftBracket
    case rightBracket
    case leftAngle
    case rightAngle
    case leftBrace
    case rightBrace
    case slash
    case eof
    
    var text: String {
        switch self {
        case .identifier(let text):
            return text
        case .string(let text):
            return text
        case .number(let value):
            return "\(value)"
        case .`class`:
            return "class"
        case .def:
            return "def"
        case .`let`:
            return "let"
        case .`in`:
            return "in"
        
        case .colon:
            return ":"
        case .semicolon:
            return ";"
        case .comma:
            return ","
        case .equals:
            return "="
        case .leftBracket:
            return "["
        case .rightBracket:
            return "]"
        case .leftAngle:
            return "<"
        case .rightAngle:
            return ">"
        case .leftBrace:
            return "{"
        case .rightBrace:
            return "}"
        case .slash:
            return "/"
        case .eof:
            return ""
        }
    }
}
