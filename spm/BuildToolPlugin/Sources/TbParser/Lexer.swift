import Foundation

class Lexer {
    private let input: String
    private var currentIndex: String.Index
    
    init(input: String) {
        self.input = input
        self.currentIndex = input.startIndex
    }
    
    private var isAtEnd: Bool {
        currentIndex >= input.endIndex
    }
    
    private func peek() -> Character? {
        guard !isAtEnd else { return nil }
        return input[currentIndex]
    }
    
    private func advance() {
        guard !isAtEnd else { return }
        currentIndex = input.index(after: currentIndex)
    }
    
    private func peekNext() -> Character? {
        guard let nextIndex = input.index(currentIndex, offsetBy: 1, limitedBy: input.endIndex) else {
            return nil
        }
        return input[nextIndex]
    }
    
    private func skipWhitespace() {
        while let char = peek() {
            switch char {
            case " ", "\t", "\n", "\r":
                advance()
            case "/" where peekNext() == "/":
                while let c = peek(), c != "\n" {
                    advance()
                }
            default:
                return
            }
        }
    }
    
    func nextToken() -> Token {
        skipWhitespace()
        
        guard let char = peek() else {
            return .eof
        }
        
        switch char {
        case "d" where matchKeyword("def"):
            return .def
        case "l" where matchKeyword("let"):
            return .let
        case "i" where matchKeyword("in"):
            return .in
        case "c" where matchKeyword("class"):
            return .class
        case "\"":
            return scanString()
        case "[":
            advance()
            return .leftBracket
        case "]":
            advance()
            return .rightBracket
        case "<":
            advance()
            return .leftAngle
        case ">":
            advance()
            return .rightAngle
        case "{":
            advance()
            return .leftBrace
        case "}":
            advance()
            return .rightBrace
        case ":":
            advance()
            return .colon
        case ";":
            advance()
            return .semicolon
        case ",":
            advance()
            return .comma
        case "=":
            advance()
            return .equals
        case "/":
            advance()
            return .slash
        case _ where char.isNumber:
            return scanNumber()
        case _ where char.isLetter || char == "_":
            return scanIdentifier()
        default:
            advance()
            return nextToken()
        }
    }
    
    private func matchKeyword(_ keyword: String) -> Bool {
        var tempIndex = currentIndex
        for char in keyword {
            guard tempIndex < input.endIndex && input[tempIndex] == char else {
                return false
            }
            tempIndex = input.index(after: tempIndex)
        }
        
        if tempIndex < input.endIndex {
            let nextChar = input[tempIndex]
            guard !nextChar.isLetter && !nextChar.isNumber && nextChar != "_" else {
                return false
            }
        }
        
        currentIndex = tempIndex
        return true
    }
    
    private func scanString() -> Token {
        advance() // Skip opening quote
        var string = ""
        
        while let char = peek(), char != "\"" {
            string.append(char)
            advance()
        }
        
        if peek() == "\"" {
            advance() // Skip closing quote
        }
        
        return .string(string)
    }
    
    private func scanNumber() -> Token {
        var number = ""
        while let char = peek(), char.isNumber {
            number.append(char)
            advance()
        }
        return .number(Int(number) ?? 0)
    }
    
    private func scanIdentifier() -> Token {
        var identifier = ""
        while let char = peek(), char.isLetter || char.isNumber || char == "_" {
            identifier.append(char)
            advance()
        }
        return .identifier(identifier)
    }
}
