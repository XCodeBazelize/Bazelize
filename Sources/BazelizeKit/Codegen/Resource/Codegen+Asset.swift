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
    func generateAssets(_ builder: CodeBuilder, _ kit: Kit) {
        /// //Example:Assets.xcassets
        /// to
        ///           Assets.xcassets/**
        let files = assets.map { label in
            "\(label)/**"
        }

        guard !files.isEmpty else { return }

        builder.call(
            Rules.Builtin.Call.filegroup(
                name: "Assets",
                srcs: Starlark.glob(files, exclude: appIconExcludes(kit)),
                visibility: .private))
    }

    /// App icons reach the bundle through the rule's `app_icons` attribute. Leaving
    /// them in the resources too makes rules_apple reject the catalog: it accepts
    /// exactly one `*.appiconset`, while Xcode projects routinely ship several and
    /// pick one with `ASSETCATALOG_COMPILER_APPICON_NAME`.
    private func appIconExcludes(_ kit: Kit) -> [String] {
        guard appIcons(project: kit.project) != nil else { return [] }
        return assets.map { label in
            "\(label)/*.appiconset/**"
        }
    }
}
