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
    func generateAssets(_ builder: CodeBuilder, _: Kit) {
        /// //Example:Assets.xcassets
        /// to
        ///           Assets.xcassets/**
        let files = assets
            .map { label in
                "\(label)/**"
            }
            .map { (label: String) in
//                if label.hasPrefix("//:") {
//                    return label.replacingOccurrences(of: "//:", with: "")
//                }
                // TODO: glob can't use `../`
                label
            }

        guard !files.isEmpty else { return }

        builder.call(
            Rules.Builtin.Call.filegroup(
                name: "Assets",
                srcs: Starlark.glob(files),
                visibility: .private))
    }
}
