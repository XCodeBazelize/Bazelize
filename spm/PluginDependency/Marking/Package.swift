// swift-tools-version: 6.0

import PackageDescription

/// A package that is nothing but a plugin: no library, no executable, nothing
/// this workspace builds a rule for. What it ships is the plugin itself, and
/// the command that plugin asks for runs a program every machine already has.
let package = Package(
    name: "Marking",
    products: [
        .plugin(name: "Mark", targets: ["Mark"]),
    ],
    targets: [
        .plugin(
            name: "Mark",
            capability: .buildTool()),
    ])
