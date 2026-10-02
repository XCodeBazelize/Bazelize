// swift-tools-version: 6.0

import PackageDescription

/// A command plugin: run on demand by `swift package hello`, never part of
/// building anything.
let package = Package(
    name: "CommandPlugin",
    products: [
        .library(name: "Greeting", targets: ["Greeting"]),
        .plugin(name: "Hello", targets: ["Hello"]),
    ],
    targets: [
        .target(name: "Greeting"),
        .plugin(
            name: "Hello",
            capability: .command(
                intent: .custom(verb: "hello", description: "Prints the package's greeting."),
                /// What such a plugin has to ask for before it may do it, and
                /// what a build must never grant it: nothing here runs it.
                permissions: [
                    .writeToPackageDirectory(reason: "Writes the greeting it prints."),
                ])),
        .testTarget(
            name: "GreetingTests",
            dependencies: ["Greeting"]),
    ])
