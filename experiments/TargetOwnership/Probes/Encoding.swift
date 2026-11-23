import Foundation

// Encodable currently inherits Copyable, independently of the stored fields.
struct OwnedTarget: ~Copyable, Encodable {
    let name: String
}
