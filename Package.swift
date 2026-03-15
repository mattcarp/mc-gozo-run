// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "mc-gozo-run",
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
                .copy("Info.plist")
            ]
        )
    ]
)
