import Foundation

#if canImport(React)
import React
import Database

private actor DatabaseHolder {
    private var database: Database.GameDatabase?

    func get() async -> Database.GameDatabase? {
        if let existing = database { return existing }
        guard let opened = await Database.GameDatabase.open() else { return nil }
        database = opened
        return opened
    }
}

@objc(Database)
public class RNDatabase: NSObject {
    private let holder = DatabaseHolder()

    @objc static func moduleName() -> String { "Database" }

    @objc static func requiresMainQueueSetup() -> Bool { false }

    @objc func getPlayer(_ name: String, email: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        Task {
            guard let database = await holder.get() else {
                resolve(["error": "Database unavailable"])
                return
            }
            if let player = await database.getPlayer(name: name, email: email) {
                resolve(["player": ["id": player.id, "name": player.name, "email": player.email]])
            } else {
                resolve(["error": "Failed to create player"])
            }
        }
    }

    @objc func saveGame(_ playerId: Double, won: Bool, difficulty: String, duration: Double, playedAt: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        Task {
            guard let database = await holder.get() else {
                resolve(["error": "Database unavailable"])
                return
            }
            await database.saveGame(playerId: UInt(playerId), won: won, difficulty: difficulty, duration: Int(duration), playedAt: playedAt)
            resolve([:])
        }
    }

    @objc func getCurrentStreak(_ playerId: Double, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        Task {
            guard let database = await holder.get() else {
                resolve(["error": "Database unavailable"])
                return
            }
            if let streak = await database.getCurrentStreak(for: UInt(playerId)) {
                resolve(["streak": ["winsCount": streak.winsCount, "startedAt": streak.startedAt]])
            } else {
                resolve(["streak": NSNull()])
            }
        }
    }

    @objc func getLeaderboard(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        Task {
            guard let database = await holder.get() else {
                resolve(["error": "Database unavailable"])
                return
            }
            let entries = await database.getLeaderboard().map {
                ["name": $0.name, "bestStreak": $0.bestStreak, "total": $0.total, "wins": $0.wins]
            }
            resolve(["leaderboard": entries])
        }
    }

}

#endif
