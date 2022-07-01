// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
    
let tag = "swift-5.5.3-RELEASE"
let package = Package(
    name: "Bazelize",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(name: "bazelize", targets: ["Bazelize"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.

//        .package(name: "SwiftPM", url: "https://github.com/apple/swift-package-manager", .revision(tag)),
//        .package(name: "SwiftTSC", url: "https://github.com/apple/swift-tools-support-core", .revision(tag)),
        .package(url: "https://github.com/tuist/XcodeProj", from: "8.7.0"),
        .package(url: "https://github.com/Flight-School/AnyCodable", from: "0.6.4"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
        .package(url: "https://github.com/kylef/PathKit", from: "1.0.1"),
        
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.1.2"),
        
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "Bazelize",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "PathKit",
                "BazelizeKit",
            ]),
        
        .target(
            name: "BazelizeKit",
            dependencies: [
                // .product(name: "PackageDescription", package: "swift-package-manager"),
                // .product(name: "SwiftPMDataModel", package: "swift-package-manager"),
                // .product(name: "SwiftPM", package: "SwiftPM"),
                // .product(name: "SwiftToolsSupport-auto", package: "SwiftTSC"),
                
                "XCode",
                "Cocoapod",
                
                .product(name: "XcodeProj", package: "XcodeProj"),
            ]),
        
        .target(
            name: "Util",
            dependencies: [
                "Yams",
                "PathKit",
            ]),
        .testTarget(
            name: "UtilTests",
            dependencies: ["Util"]
        ),
        
        .target(
            name: "XCode",
            dependencies: [
                "Util",
                
                .product(name: "XcodeProj", package: "XcodeProj"),
            ]),
        
        .target(
            name: "Cocoapod",
            dependencies: [
                "Util",
                "AnyCodable",
                "PathKit",
            ]),
        .testTarget(
            name: "CocoapodTests",
            dependencies: ["Cocoapod"],
            resources: [
                .copy("Resource")
            ]
        ),
        
//        .testTarget(
//            name: "SwiftBazelGenTests",
//            dependencies: ["SwiftBazelGen"]),
    ]
)
