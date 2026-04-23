import Foundation

extension Starlark {
    public enum Statement: Text {
        case comment(Starlark.Comment)
        case custom(String)
        case newLine
        case load(Load)
        case call(Call)
        
        static func call(_ name: String) -> Statement {
            .call(Call(name, []))
        }
        
        public var text: String {
            switch self {
            case let .comment(value):
                return value.text
            case let .custom(value):
                return value
            case .newLine:
                return "\n"
            case let .load(load):
                return load.text
            case let .call(call):
                return call.text
            }
        }
    }
}
