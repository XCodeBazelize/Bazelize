// swift-tools-version: 6.0

import PackageDescription

/// `exclude:`: everything under the target's directory is compiled except what
/// the manifest names.
///
/// No products, either: a package can be nothing but targets — an app's own,
/// built and tested and depended on by nothing — and a generator that assumes
/// a library to hang the targets off would have nothing to write.
let package = Package(
    name: "TargetExclude",
    targets: [
        .target(
            name: "TargetExclude",
            /// A directory and a single file, to cover both forms.
            exclude: ["Excluded", "Notes.swift"]),
        .testTarget(
            name: "TargetExcludeTests",
            dependencies: ["TargetExclude"]),
    ])
