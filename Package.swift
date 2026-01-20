// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "iPodKit",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "iPodKit",
            targets: ["iPodKit"]),
        .executable(
            name: "analyze-itunes-db",
            targets: ["iTunesDBAnalyzer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
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
