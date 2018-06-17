// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Streams",
    products: [
        .library(
            name: "Streams",
            targets: ["Streams"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Streams",
            dependencies: []),
        .testTarget(
            name: "StreamsTests",
            dependencies: ["Streams"]),
    ]
)
