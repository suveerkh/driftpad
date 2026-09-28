// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Driftpad",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Driftpad",
            path: "Sources/Driftpad",
            resources: [.process("Resources")]
        )
    ]
)