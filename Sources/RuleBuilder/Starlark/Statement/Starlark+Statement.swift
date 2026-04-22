import Foundation

extension Starlark {
    public enum Statement: Text {
        case comment(String)
        case load(Load)
        case call(Call)
        
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
