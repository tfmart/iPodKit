// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "iPodKit",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "iPodKit",
            targets: ["iPodKit"]),
        .executable(
            name: "ipodkit",
            targets: ["iPodKitCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.0"),
        .package(url: "https://github.com/swiftlang/swift-docc-plugin.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    ],
    targets: [
        .target(
            name: "iPodKit",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift")
            ]
        ),
        .target(
            name: "iPodKitCLICore",
            dependencies: ["iPodKit"]
        ),
        .executableTarget(
            name: "iPodKitCLI",
            dependencies: [
                "iPodKit",
                "iPodKitCLICore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "iPodKitTests",
            dependencies: ["iPodKit"],
            resources: [
                .copy("Resources")
            ]
        ),
        .testTarget(
            name: "iPodKitCLITests",
            dependencies: ["iPodKitCLICore", "iPodKit"],
            resources: [
                .copy("Resources")
            ]
        ),
    ]
)
