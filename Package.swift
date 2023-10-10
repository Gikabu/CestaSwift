// swift-tools-version: 5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Cesta",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(name: "Cesta", targets: ["Cesta"]),
    ],
    dependencies: [
        .package(name:"Realm", url: "https://github.com/realm/realm-swift", .upToNextMajor(from: "10.43.0")),
        .package(url: "https://github.com/SwiftyBeaver/SwiftyBeaver.git", .upToNextMajor(from: "2.0.0")),
    ],
    targets: [
        .target(
            name: "Cesta",
            dependencies: [
                .product(name: "RealmSwift", package: "Realm"),
                "SwiftyBeaver"
            ]
        ),
        .testTarget(name: "CestaTests", dependencies: ["Cesta"]),
    ]
)
