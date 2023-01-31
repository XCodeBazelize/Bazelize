// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "MySwiftPackage",
    dependencies: [
        .package(url: "https://github.com/Flight-School/AnyCodable", from: "0.6.7"),
        .package(path: "Local1"),
    ])