// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "union-keychain",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "UnionKeychain",
            targets: ["UnionKeychain"]
        ),
    ],
    targets: [
        .target(
            name: "UnionKeychain"
        ),
    ]
)
