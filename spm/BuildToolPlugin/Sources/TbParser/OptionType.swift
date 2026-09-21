import Foundation

/// Definition of different option types
enum OptionType: Equatable {
    /// Flag<["-"], "help">
    /// -help
    case flag(prefix: String, name: String)
    // Joined<["-"], "I">
    // -I/usr/include
    case joined(prefix: String, name: String)
    /// Separate<["-"], "output">
    /// -output file.txt
    case separate(prefix: String, name: String)
    /// CommaJoined<["-"], "arch">
    /// -arch=x86_64,arm64
    case commaJoined(prefix: String, name: String)
    /// MultiArg<["-"], "framework", 2>
    /// -framework UIKit Foundation
    case multiArg(prefix: String, name: String, count: Int)
    /// JoinedOrSeparate<["-"], "I">
    /// -I/usr/include
    /// -I /usr/include
    case joinedOrSeparate(prefix: String, name: String)
    /// JoinedAndSeparate<["-"], "Xlinker">
    /// -XlinkerInput1 Input2
    case joinedAndSeparate(prefix: String, name: String)
    
    static func contains(_ text: String) -> Bool {
        switch text {
        case "Flag",
            "Joined",
            "Separate",
            "CommaJoined",
            "MultiArg",
            "JoinedOrSeparate",
            "JoinedAndSeparate":
            return true
        default:
            return false
        }
    }
    
    var commandLineFlag: String {
        switch self {
        case .flag(let prefix, let name),
             .joined(let prefix, let name),
             .separate(let prefix, let name),
             .commaJoined(let prefix, let name),
             .multiArg(let prefix, let name, _),
             .joinedOrSeparate(let prefix, let name),
             .joinedAndSeparate(let prefix, let name):
            return prefix + name
        }
    }
}
