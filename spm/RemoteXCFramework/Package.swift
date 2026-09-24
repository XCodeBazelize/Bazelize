// swift-tools-version: 6.0

import PackageDescription

/// A remote dynamic XCFramework fetched and unpacked by SwiftPM.
let package = Package(
    name: "RemoteXCFramework",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        .library(name: "RemoteXCFramework", targets: ["Sparkle"]),
    ],
    targets: [
        .binaryTarget(
            name: "Sparkle",
            url: "https://github.com/sparkle-project/Sparkle/releases/download/2.3.0/Sparkle-for-Swift-Package-Manager.zip",
            checksum: "a32f43511071c4df4e3aa766ed3e8e0fc03dd5912d8a0db9e266794735ad247f"),
        .testTarget(
            name: "RemoteXCFrameworkTests",
            dependencies: ["Sparkle"]),
    ])
