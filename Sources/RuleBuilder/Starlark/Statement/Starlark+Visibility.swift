//
//  Property+Visibility.swift
//
//
//  Created by Yume on 2022/8/9.
//

import Foundation

// MARK: - Starlark.Statement.Argument.Visibility

extension Starlark.Statement.Argument {
    /// https://bazel.build/concepts/visibility
    public struct Visibility: Sendable {
        /// "//visibility:public": Anyone can use this target. (May not be combined with any other specification.)
        public static let `public`: Self = ["//visibility:public"]
        /// "//visibility:private": Only targets in this package can use this target. (May not be combined with any other specification.)
        public static let `private`: Self = ["//visibility:private"]

        /// "//foo/bar:__pkg__": Grants access to targets defined in //foo/bar (but not its subpackages). Here, __pkg__ is a special piece of syntax representing all of the targets in a package.
        public static func package(_ packages: String...) -> Self {
            group("__pkg__", packages)
        }

        /// "//foo/bar:__subpackages__": Grants access to targets defined in //foo/bar, or any of its direct or indirect subpackages. Again, __subpackages__ is special syntax.
        public static func subPackage(_ packages: String...) -> Self {
            group("__subpackages__", packages)
        }

        /// "//foo/bar:my_package_group": Grants access to all of the packages named by the given package group.
        public static func group(_ group: String, _ packages: String...) -> Self {
            self.group(group, packages)
        }

        /// "//foo/bar:my_package_group": Grants access to all of the packages named by the given package group.
        public static func group(_ group: String, _ packages: [String]) -> Self {
            .init(value: packages.map { package in
                "\(package):\(group)"
            })
        }

        private let value: [String]
        public init(value: [String]) {
            self.value = value
        }

        public var argument: Starlark.Statement.Argument {
            "visibility" => value
        }
    }
}

// MARK: - Starlark.Statement.Argument.Visibility + ExpressibleByArrayLiteral

extension Starlark.Statement.Argument.Visibility: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: String...) {
        value = elements
    }
}
