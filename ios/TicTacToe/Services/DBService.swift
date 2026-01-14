import Foundation
import Database

protocol DBServiceProtocol: Sendable {
    func save(_ record: GameRecord) async
    func getStreak(for playerId: UInt) async -> StreakInfo
    func getLeaderboard() async -> [LeaderboardEntry]
}

final class DBService: DBServiceProtocol, @unchecked Sendable {
    private let database: GameDatabase?

    init(database: GameDatabase?) {
        self.database = database
    }

    func save(_ record: GameRecord) async {
        await database?.saveGame(
            playerId: record.playerId,
            won: record.won,
            difficulty: record.difficulty,
            duration: record.duration,
            playedAt: record.playedAt
        )
    }

    func getStreak(for playerId: UInt) async -> StreakInfo {
        guard let db = database else {
            return StreakInfo(current: 0, best: nil)
        }

        let current = await db.getCurrentStreak(for: playerId)

        var best: BestStreakInfo? = nil
        if let bestData = await db.getBestStreak(for: playerId), bestData.count > 0 {
            best = BestStreakInfo(
                count: bestData.count,
                startDate: bestData.startDate,
                endDate: bestData.endDate
            )
        }

        return StreakInfo(current: current, best: best)
    }

    func getLeaderboard() async -> [LeaderboardEntry] {
        await database?.getLeaderboard() ?? []
    }
}
