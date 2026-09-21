import Foundation

enum SwiftKeyword: String {
    case `static`
    case `class`
    case `func`
    
    var name: String {
        return "`\(rawValue)`"
    }
}
