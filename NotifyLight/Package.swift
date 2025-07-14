// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NotifyLight",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "NotifyLight",
            targets: ["NotifyLight"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "NotifyLight",
            dependencies: [],
            path: "Sources/NotifyLight",
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .testTarget(
            name: "NotifyLightTests",
            dependencies: ["NotifyLight"]
        ),
    ]
)