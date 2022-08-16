//
//  Property+Visibility.swift
//
//
//  Created by Yume on 2022/8/9.
//

import Foundation

extension StarlarkProperty {
    /// https://bazel.build/concepts/visibility
    public enum Visibility {
        /// "//visibility:public": Anyone can use this target. (May not be combined with any other specification.)
        public static let `public`: StarlarkProperty = "visibility" => "//visibility:public"
        /// "//visibility:private": Only targets in this package can use this target. (May not be combined with any other specification.)
        public static let `private`: StarlarkProperty = "visibility" => "//visibility:private"

        /// "//foo/bar:__pkg__": Grants access to targets defined in //foo/bar (but not its subpackages). Here, __pkg__ is a special piece of syntax representing all of the targets in a package.
        public static func package(_ packages: String...) -> StarlarkProperty {
            group("__pkg__", packages)
        }

        /// "//foo/bar:__subpackages__": Grants access to targets defined in //foo/bar, or any of its direct or indirect subpackages. Again, __subpackages__ is special syntax.
        public static func subPackage(_ packages: String...) -> StarlarkProperty {
            group("__subpackages__", packages)
        }

        /// "//foo/bar:my_package_group": Grants access to all of the packages named by the given package group.
        public static func group(_ group: String, _ packages: String...) -> StarlarkProperty {
            self.group(group, packages)
        }

        /// "//foo/bar:my_package_group": Grants access to all of the packages named by the given package group.
        public static func group(_ group: String, _ packages: [String]) -> StarlarkProperty {
            StarlarkProperty("visibility") {
                packages.map { package in
                    "\(package):\(group)"
                }
            }
        }
    }
}
