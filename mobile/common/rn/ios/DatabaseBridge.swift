import Foundation

@objcMembers
public class DatabaseBridge: NSObject, @unchecked Sendable {
    private let database = GameDatabase.open()
    private let queue = DispatchQueue.main

    public func getPlayerId(name: String, resolve: @escaping ResolveBlock, reject: @escaping RejectBlock) {
        Task { [self, resolve] in
            guard let db = database else {
                queue.async { resolve(["error": "Database unavailable"]) }
                return
            }
            if let playerId = await db.getPlayerId(name: name) {
                queue.async { resolve(["playerId": playerId]) }
            } else {
                queue.async { resolve(["error": "Failed to get player"]) }
            }
        }
    }

    public func saveGame(playerId: Double, won: Bool, difficulty: String, duration: Double, playedAt: String, resolve: @escaping ResolveBlock, reject: @escaping RejectBlock) {
        Task { [self, resolve] in
            guard let db = database else {
                queue.async { resolve(["error": "Database unavailable"]) }
                return
            }
            await db.saveGame(playerId: UInt(playerId), won: won, difficulty: difficulty, duration: Int(duration), playedAt: playedAt)
            queue.async { resolve([:]) }
        }
    }

    public func getCurrentStreak(playerId: Double, resolve: @escaping ResolveBlock, reject: @escaping RejectBlock) {
        Task { [self, resolve] in
            guard let db = database else {
                queue.async { resolve(["error": "Database unavailable"]) }
                return
            }
            let streak = await db.getCurrentStreak(for: UInt(playerId))
            queue.async { resolve(["streak": streak]) }
        }
    }

    public func getBestStreak(playerId: Double, resolve: @escaping ResolveBlock, reject: @escaping RejectBlock) {
        Task { [self, resolve] in
            guard let db = database else {
                queue.async { resolve(["error": "Database unavailable"]) }
                return
            }
            if let best = await db.getBestStreak(for: UInt(playerId)) {
                queue.async { resolve(["count": best.count, "startDate": best.startDate, "endDate": best.endDate]) }
            } else {
                queue.async { resolve(["count": 0]) }
            }
        }
    }

    public func getLeaderboard(resolve: @escaping ResolveBlock, reject: @escaping RejectBlock) {
        Task { [self, resolve] in
            guard let db = database else {
                queue.async { resolve(["error": "Database unavailable"]) }
                return
            }
            let entries = await db.getLeaderboard().map {
                ["playerId": $0.playerId, "name": $0.name, "bestStreak": $0.bestStreak, "streakDuration": $0.streakDuration, "total": $0.total, "wins": $0.wins]
            }
            queue.async { resolve(["leaderboard": entries]) }
        }
    }
}
