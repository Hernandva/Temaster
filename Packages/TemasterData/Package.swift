// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TemasterData",
    platforms: [.iOS("18.0"), .macOS("15.0")],
    products: [
        .library(name: "TemasterData", targets: ["TemasterData"])
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.10.0")
    ],
    targets: [
        .target(
            name: "TemasterData",
            dependencies: [.product(name: "Alamofire", package: "Alamofire")]
        ),
        .testTarget(
            name: "TemasterDataTests",
            dependencies: ["TemasterData"]
        )
    ],
    swiftLanguageModes: [.v6]
)
