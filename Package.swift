// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "GozoRun",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "GozoRun",
            targets: ["GozoRun"]
        )
    ],
    targets: [
        .target(
            name: "GozoRun",
            path: "Sources/GozoRun",
            resources: [
                .process("route.gpx"),
                .copy("Info.plist")
            ]
        )
    ]
)
