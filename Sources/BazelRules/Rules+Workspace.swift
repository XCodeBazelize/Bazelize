//
//  Rules+Workspace.swift
//
//
//  The rules a generated workspace carries itself, under `tools/`.
//

import Foundation
import Starlark

// MARK: - Rules.Workspace

extension Rules {
    /// Rules no ruleset provides, written into the workspace beside the rules
    /// that use them.
    public enum Workspace: String, LoadableRule {
        public var module: String {
            "//tools:\(rawValue).bzl"
        }

        case asset_symbols
    }
}

// MARK: - Rules.Workspace.Call

extension Rules.Workspace {
    public enum Call {
        /// Builds an `asset_symbols` target.
        ///
        /// `platform` is what the target was read as, and is only reached when the
        /// configuration carries no Apple platform constraint — a build of the
        /// rule on its own, outside the bundle that transitions to its platform.
        public static func asset_symbols(
            name: String,
            catalogs: Starlark.Value,
            bundle_id: String,
            minimum_os_version: String,
            platform: String,
            visibility: Starlark.Statement.Argument.Visibility? = nil) -> Starlark.Statement.Call
        {
            Rules.Workspace.asset_symbols.call {
                "name" => name
                "bundle_id" => bundle_id
                "catalogs" => catalogs
                "minimum_os_version" => minimum_os_version
                "platform" => platform
                if let visibility {
                    visibility.argument
                }
            }
        }
    }
}
