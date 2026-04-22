import Foundation

extension Starlark {
    public enum Statement: Text {
        case comment(String)
        case load(Load)
        case call(Call)
        
        static func call(_ name: String) -> Statement {
            .call(Call(name, []))
        }
        
        public var text: String {
            switch self {
            case let .comment(value):
                return value.comment
            case let .load(load):
                return load.text
            case let .call(call):
                return call.text
            }
        }
    }
}
