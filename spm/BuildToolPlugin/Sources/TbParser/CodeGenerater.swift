import Foundation

public struct CodeGenerater {
    public static func generate(
        name: String,
        content: String
    ) throws -> String {
        let options = try TableGenParser.parse(content)
        return """
        public enum \(name) {
        \(generateCase(options).indent())
        
        \(generateFlags(options).indent())
        }
        """
    }
    
    private static func generateCase(_ options: [OptionDefinition]) -> String {
        return options.map(\.caseDefinition).joined(separator: "\n")
    }
    
    private static func generateFlags(_ options: [OptionDefinition]) -> String {
        let flags = options.map(\.flagDefinition).joined(separator: "\n")
        return """
        public var flags: [String] {
            switch self {
        \(flags.indent())
            }
        }
        """
    }
}

fileprivate extension OptionDefinition {
    var flagDefinition: String {
        var contents: [String] = []
        switch type {
        case .flag:
            contents.append("""
            case .\(name):
                return ["\(type.commandLineFlag)"]
            """)
        case .joined:
            contents.append("""
            case .\(name)(let arg):
                return ["\(type.commandLineFlag)\\(arg)"]
            """)
        case .separate: fallthrough
        case .joinedOrSeparate:
            contents.append("""
            case .\(name)(let arg):
                return ["\(type.commandLineFlag)", arg]
            """)
            /// args
        case .commaJoined:
            contents.append("""
            case .\(name)(let args):
                let commaArg = args.joined(separator: ",")
                return ["\(type.commandLineFlag)=\\(commaArg)"]
            """)
            /// args
        case .multiArg:
            contents.append("""
            case .\(name)(let args):
                return ["\(type.commandLineFlag)"] + args
            """)
            /// arg1 2
        case .joinedAndSeparate:
            contents.append("""
            case .\(name)(let arg1, let arg2):
                return ["\(type.commandLineFlag)\\(arg1)", arg2]
            """)
        }
        return contents.joined(separator: "\n")
    }
    
    var caseDefinition: String {
        var contents: [String] = []
        
        if !helpText.isEmpty {
            contents.append("""
            /// \(helpText)
            """)
        }
        
        let flags = flags.union(letBlockFlags)
        if !flags.isEmpty {
            contents.append("""
            /// Flags: \(flags.sorted().joined(separator: ", "))
            """)
        }
        
        if let metaVarName {
            contents.append("""
            /// Meta var name: \(metaVarName)
            """)
        }
        
        if let aliasOf {
            contents.append("""
            /// Alias of: \(aliasOf)
            """)
        }
        
        if !otherOptions.isEmpty {
            contents.append("""
            /// Other options: \(otherOptions.sorted().joined(separator: ", "))
            """)
        }
        
        if !otherGroup.isEmpty {
            contents.append("""
            /// Other groups: \(otherGroup.sorted().joined(separator: ", "))
            """)
        }
        let name = SwiftKeyword(rawValue: self.name)?.name ?? self.name
        
        switch type {
        case .flag:
            contents.append("""
            case \(name)
            """)
        case .joined: fallthrough
        case .separate: fallthrough
        case .joinedOrSeparate:
            contents.append("""
            case \(name)(arg: String)
            """)
        case .commaJoined: fallthrough
        case .multiArg:
            contents.append("""
            case \(name)(args: [String])
            """)
        case .joinedAndSeparate:
            contents.append("""
            case \(name)(arg1: String, arg2: String)
            """)
        }
        
        return contents.joined(separator: "\n")
    }
}

fileprivate extension String {
    func indent(_ count: Int = 1, _ word: String = "    ") -> String {
        let prefix = Array(repeating: word, count: count).joined(separator: "")
        return split(separator: "\n")
            .map { sub in
                sub.appending(prefix: prefix)
            }
            .joined(separator: "\n")
    }
}

fileprivate extension StringProtocol {
    func appending(prefix: String) -> String {
        prefix + self
    }
}
