// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "GozoRun",
    platforms: [
        .iOS(.v17)
    ],
    targets: [
        .executableTarget(
            name: "GozoRun",
            path: "Sources/GozoRun",
            exclude: ["Info.plist"],
            resources: [
                .process("route.gpx")
            ]
        )
    ]
)
