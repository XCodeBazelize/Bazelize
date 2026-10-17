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

        case apple_simulator_test
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

        /// Runs a rules_apple test bundle in a non-iOS Apple Simulator.
        public static func apple_simulator_test(
            name: String,
            bundle: Starlark.Label,
            destination_platform: String,
            developer_platform: String,
            product_family: String,
            runtime_platform: String,
            target_compatible_with: [String],
            timeout: String? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil) -> Starlark.Statement.Call
        {
            Rules.Workspace.apple_simulator_test.call {
                "name" => name
                "bundle" => bundle
                "destination_platform" => destination_platform
                "developer_platform" => developer_platform
                "product_family" => product_family
                "runtime_platform" => runtime_platform
                "target_compatible_with" =>
                    target_compatible_with.map { Starlark.Label.named($0) }
                if let timeout { "timeout" => timeout }
                if let visibility { visibility.argument }
            }
        }
    }
}
