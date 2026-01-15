// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "TicTacToeCore",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "GameLogic", targets: ["GameLogic"]),
        .library(name: "Database", targets: ["Database"]),
        .library(name: "Network", targets: ["Network"])
    ],
    targets: [
        .target(name: "GameLogic"),
        .target(name: "Database"),
        .target(name: "Network")
    ]
)
