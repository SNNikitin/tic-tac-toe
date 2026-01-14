import Foundation

struct BestStreakInfo {
    let count: Int
    let startDate: String
    let endDate: String

    var formatted: String {
        "\(count) wins (\(Self.formatDate(startDate)) - \(Self.formatDate(endDate)))"
    }

    private static func formatDate(_ isoString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd.MM.yyyy"

        for options: ISO8601DateFormatter.Options in [[.withInternetDateTime, .withFractionalSeconds], [.withInternetDateTime]] {
            isoFormatter.formatOptions = options
            if let date = isoFormatter.date(from: isoString) {
                return outputFormatter.string(from: date)
            }
        }
        return isoString
    }
}

struct StreakInfo {
    let current: Int
    let best: BestStreakInfo?
}

struct GameRecord {
    let playerId: UInt
    let won: Bool
    let difficulty: String
    let duration: Int
    let playedAt: String
}

struct GamePayload {
    let email: String
    let playerName: String
    let won: Bool
    let difficulty: String
    let duration: Int
    let playedAt: String
    let streak: Int
}

typealias LeaderboardEntry = (name: String, bestStreak: Int, streakDuration: Int, total: Int, wins: Int)
