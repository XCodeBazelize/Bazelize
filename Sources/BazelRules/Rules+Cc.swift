import Foundation
import Starlark

// MARK: - Rules.Cc

extension Rules {
    public enum Cc: String, LoadableRule {
        case cc_import

        public var module: String {
            "@rules_cc//cc:defs.bzl"
        }
    }
}

// MARK: - Rules.Cc.Call

extension Rules.Cc {
    public enum Call {
        public static func cc_import(
            name: String,
            shared_library: Starlark.Label? = nil,
            static_library: Starlark.Label? = nil,
            interface_library: Starlark.Label? = nil,
            hdrs: Starlark.Value? = nil,
            system_provided: Bool? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Cc.cc_import.call {
                "name" => name
                if let shared_library { "shared_library" => shared_library }
                if let static_library { "static_library" => static_library }
                if let interface_library { "interface_library" => interface_library }
                if let hdrs { "hdrs" => hdrs }
                if let system_provided { "system_provided" => system_provided }
                if let visibility { visibility }
            }
        }
    }
}
