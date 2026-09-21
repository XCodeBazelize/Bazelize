import Foundation

struct OptionKind: Equatable {
    let name: String
    /// The kind precedence, kinds with lower precedence are matched first.
    let precedence: Int
    /// Indicate a sentinel option.
    let sentinel: Bool
}

struct OptionFlag: Equatable {}
struct OptionVisibility: Equatable {}
