// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SpaceCLI",
    products: [], dependencies: [
        .package(url: "https://github.com/swiftlang/swift-package-manager", revision: "630330a"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "SpaceCLI",
            dependencies: [
                .product(name: "SwiftPM-auto", package: "swift-package-manager"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        )
    ]
)
