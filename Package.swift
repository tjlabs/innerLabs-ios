// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JupiterSDK",
    platforms: [.iOS(.v12)],
    products: [
        .library(
            name: "JupiterSDK",
            targets: ["JupiterSDK"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "JupiterSDK",
            dependencies: []),
        .testTarget(
            name: "JupiterSDKTests",
            dependencies: ["JupiterSDK"]),
    ]
)
