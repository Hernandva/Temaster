// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TemasterUI",
    defaultLocalization: "en",
    platforms: [.iOS("18.0"), .macOS("15.0")],
    products: [
        .library(name: "TemasterUI", targets: ["TemasterUI"])
    ],
    targets: [
        .target(
            name: "TemasterUI",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "TemasterUITests",
            dependencies: ["TemasterUI"]
        )
    ],
    swiftLanguageModes: [.v6]
)
