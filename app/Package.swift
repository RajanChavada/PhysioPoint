// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "PhysioPoint",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "PhysioPoint",
            targets: ["PhysioPoint"]
        ),
    ],
    dependencies: [
        // No external dependencies according to SSC requirements
    ],
    targets: [
        .executableTarget(
            name: "PhysioPoint",
            path: "Sources/PhysioPoint"
        )
    ]
)
