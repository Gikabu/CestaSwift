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
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", .upToNextMajor(from: "0.9.17")),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON", .upToNextMajor(from: "5.0.1")),
    ],
    targets: [
        .target(
            name: "Cesta",
            dependencies: [
                .product(name: "RealmSwift", package: "Realm"),
                "SwiftyBeaver",
                "ZIPFoundation",
                "SwiftyJSON"
            ]
        ),
        .testTarget(name: "CestaTests", dependencies: ["Cesta"]),
    ]
)
