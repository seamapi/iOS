// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SeamComponents",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15),
        .watchOS(.v7),
    ],
    products: [
        .library(
            name: "SeamComponents",
            type: .dynamic,
            targets: [
                "SeamComponents",
            ]
        ),
    ],
    targets: [
        .target(
            name: "SeamComponents",
            resources: [
                .process("Resources/Localizable.xcstrings"),
                .process("Resources/Assets.xcassets"),
                .process("Resources/phone-and-salto-lock.gif")
            ]
        ),
    ]
)
