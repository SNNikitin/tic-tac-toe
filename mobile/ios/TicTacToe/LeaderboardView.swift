import SwiftUI
import Database

typealias LeaderboardEntry = (name: String, bestStreak: Int, streakDuration: Int, total: Int, wins: Int)

struct LeaderboardView: View {
    let db: GameDatabase?
    @State private var entries: [LeaderboardEntry] = []
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                Spacer()
                ProgressView("Loading...")
                Spacer()
            } else if entries.isEmpty {
                Spacer()
                Text("No games yet")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.secondaryText)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(entries.indices, id: \.self) { i in
                            LeaderboardRow(rank: i + 1, entry: entries[i])
                        }
                    }
                    .padding(16)
                }
            }
        }
        .background(Color.white)
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            entries = await db?.getLeaderboard() ?? []
            isLoading = false
        }
    }
}

struct LeaderboardRow: View {
    let rank: Int
    let entry: LeaderboardEntry

    private var winRate: Int {
        guard entry.total > 0 else { return 0 }
        return Int(Double(entry.wins) / Double(entry.total) * 100)
    }

    private var duration: String {
        let sec = entry.streakDuration
        if sec < 60 { return "\(sec)s" }
        if sec < 3600 { return "\(sec / 60)m" }
        return "\(sec / 3600)h \((sec % 3600) / 60)m"
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text("#\(rank)")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.accent)
                .frame(width: 40, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.name)
                    .font(.system(size: 18, weight: .medium))

                Text("Best streak: \(entry.bestStreak) (\(duration)) | Win rate: \(winRate)% (\(entry.wins)/\(entry.total))")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.secondaryText)
            }

            Spacer()
        }
        .padding(.vertical, 12)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color.separator),
            alignment: .bottom
        )
    }
}
