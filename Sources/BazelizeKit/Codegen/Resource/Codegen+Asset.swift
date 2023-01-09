//
//  Asset.swift
//
//
//  Created by Yume on 2023/1/9.
//

import Foundation
import RuleBuilder
import XCode

extension Target {
    /// https://thanhvu.dev/en/2021/07/16/migrating-ios-project-to-bazel-part-2-2/
    /// filegroup(
    ///     name = "Assets",
    ///     srcs = glob(["Assets.xcassets/**"]),
    ///     visibility = ["//visibility:public"],
    /// )
    ///
    /// data = [
    ///     "//Assets:Assets",
    ///     "Base.lproj/Main.storyboard",
    ///     "Base.lproj/LaunchScreen.storyboard",
    /// ],
    func generateAssets(_ builder: inout Build.Builder, _: Kit) {
        /// //Example:Assets.xcassets
        /// to
        ///           Assets.xcassets/**
        let files = assets
            .map { label in
                "\(label.delete(prefix: "//\(name):"))/**"
            }

        guard !files.isEmpty else { return }

        let asset = Starlark(files) ?? .none
        builder.add("filegroup") {
            "name" => "Assets"
            "srcs" => Starlark.custom("""
            glob(\(asset.text))
            """)
            StarlarkProperty.Visibility.private
        }
    }
}
