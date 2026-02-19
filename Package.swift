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
            name: "analyze-itunes-db",
            targets: ["iTunesDBAnalyzer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.0"),
        .package(url: "https://github.com/swiftlang/swift-docc-plugin.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "iPodKit",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift")
            ]
        ),
        .executableTarget(
            name: "iTunesDBAnalyzer",
            dependencies: ["iPodKit"]),
        .testTarget(
            name: "iPodKitTests",
            dependencies: ["iPodKit"],
            resources: [
                .copy("Resources")
            ]
        ),
    ]
)
