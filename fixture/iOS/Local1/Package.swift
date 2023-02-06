// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Local1",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "LocalLib1",
            targets: ["LocalTarget1", "LocalTarget3"]),
        .library(
            name: "LocalLib2",
            targets: ["LocalTarget2"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/ReactiveX/RxSwift", from: "6.5.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "LocalTarget1",
            dependencies: ["RxSwift"]),
        .target(
            name: "LocalTarget2",
            dependencies: ["RxSwift"]),
        .target(
            name: "LocalTarget3"),
        .testTarget(
            name: "Local1Tests",
            dependencies: ["LocalTarget1"]),
    ])
