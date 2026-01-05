// swift-tools-version:5.9
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
        .target(name: "GameLogic", path: "gamelogic", sources: ["Game.swift", "Models.swift"]),
        .target(name: "Database", path: "database", sources: ["Database.swift"]),
        .target(name: "Network", path: "network", sources: ["Network.swift"])
    ]
)
