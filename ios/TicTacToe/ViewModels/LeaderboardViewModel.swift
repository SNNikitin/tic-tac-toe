import Foundation

@MainActor
final class LeaderboardViewModel: ObservableObject {
    @Published private(set) var entries: [LeaderboardEntry] = []
    @Published private(set) var isLoading = true

    private let repository: GameRepositoryProtocol?

    init(repository: GameRepositoryProtocol?) {
        self.repository = repository
    }

    func load() async {
        guard let repo = repository else {
            isLoading = false
            return
        }
        entries = await repo.getLeaderboard()
        isLoading = false
    }

    func winRate(for entry: LeaderboardEntry) -> Int {
        entry.total > 0 ? Int(Double(entry.wins) / Double(entry.total) * 100) : 0
    }

    func formattedDuration(for entry: LeaderboardEntry) -> String {
        let seconds = entry.streakDuration
        if seconds < 60 { return "\(seconds)s" }
        if seconds < 3600 { return "\(seconds / 60)m" }
        return "\(seconds / 3600)h \((seconds % 3600) / 60)m"
    }
}
