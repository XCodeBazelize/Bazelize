//
//  Rules+Workspace.swift
//
//
//  The rules a generated workspace carries itself.
//

import Foundation
import Starlark

// MARK: - Rules.Workspace

extension Rules {
    /// Rules no ruleset provides, written into the workspace beside the rules
    /// that use them.
    public enum Workspace: String, LoadableRule {
        public var module: String {
            switch self {
            case .apple_simulator_test, .asset_symbols:
                "//tools:\(rawValue).bzl"
            case .swiftpm_resource_bundle:
                "//Packages:\(rawValue).bzl"
            }
        }

        case apple_simulator_test
        case asset_symbols
        case swiftpm_resource_bundle
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
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Workspace.asset_symbols.call {
                Attr.name(name)
                Attr.bundle_id(bundle_id)
                Attr.catalogs(catalogs)
                Attr.minimum_os_version(minimum_os_version)
                Attr.platform(platform)
                Attr.visibility(visibility)
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
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Workspace.apple_simulator_test.call {
                Attr.name(name)
                Attr.bundle(bundle)
                Attr.destination_platform(destination_platform)
                Attr.developer_platform(developer_platform)
                Attr.product_family(product_family)
                Attr.runtime_platform(runtime_platform)
                Attr.target_compatible_with(target_compatible_with.map { Starlark.Label.named($0) })
                Attr.timeout(timeout)
                Attr.visibility(visibility)
            }
        }

        /// Materializes the resource bundle a standalone executable carries.
        public static func swiftpm_resource_bundle(
            name: String,
            archive: Starlark.Label,
            bundle_name: String,
            tags: [String]? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Workspace.swiftpm_resource_bundle.call {
                Attr.name(name)
                Attr.archive(archive)
                Attr.bundle_name(bundle_name)
                Attr.tags(tags)
            }
        }
    }
}
