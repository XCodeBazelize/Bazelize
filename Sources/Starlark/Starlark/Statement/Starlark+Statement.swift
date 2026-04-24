import Foundation

extension Starlark {
    public enum Statement: Text {
        case comment(Starlark.Comment)
        case custom(String)
        case newLine
        case load(Load)
        case call(Call)

        public static func call(
            rule: String,
            properties: [ArgumentBuilder.Target])
            -> Statement
        {
            .call(Call(rule, properties))
        }

        public var text: String {
            switch self {
            case .comment(let value):
                return value.text
            case .custom(let value):
                return value
            case .newLine:
                return ""
            case .load(let load):
                return load.text
            case .call(let call):
                return call.text
            }
        }
    }
}
