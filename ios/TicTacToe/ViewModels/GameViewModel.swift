import SwiftUI
import GameLogic
import Database

@MainActor
final class GameViewModel: ObservableObject {
    @Published var syncState: SyncState = .idle
    @Published var syncError: String?
    @Published var currentStreak: Int = 0
    @Published var bestStreak: BestStreakInfo?

    let game: Game

    private var playerRepository: PlayerRepositoryProtocol?
    private var gameRepository: GameRepositoryProtocol?
    private let apiService: GameAPIServiceProtocol = GameAPIService()

    private var currentPlayerId: UInt?
    private var savedName: String?
    private var savedPlayedAt: String?

    enum SyncState {
        case idle, saving, saved, sending, sent, error
    }

    var board: GameBoard { game.state.board }
    var difficulty: DifficultyLevel { game.state.difficulty }
    var winningLine: [Position]? { game.state.winningLine }
    var isGameOver: Bool { game.state.isGameOver }
    var isHumanTurn: Bool { game.state.isHumanTurn }
    var canTap: Bool { isHumanTurn && !isGameOver }

    var statusText: String {
        if isGameOver {
            if game.state.humanWon { return "You win!" }
            if game.state.result == .draw { return "Draw!" }
            return "You lose!"
        }
        return isHumanTurn ? "Your turn" : "Computer thinking..."
    }

    var statusColor: UInt {
        if isGameOver {
            if game.state.humanWon { return 0x34C759 }
            if game.state.result == .draw { return 0xFF9500 }
            return 0xFF3B30
        }
        return isHumanTurn ? 0x007AFF : 0x666666
    }

    func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    func makeLeaderboardViewModel() -> LeaderboardViewModel {
        LeaderboardViewModel(repository: gameRepository)
    }

    init() {
        self.game = Game()
        Task {
            await initRepositories()
        }
    }

    private func initRepositories() async {
        let database = await GameDatabase.open()
        playerRepository = PlayerRepository(database: database)
        gameRepository = GameRepository(database: database)
        objectWillChange.send()
    }

    func newGame() {
        game.newGame()
        syncState = .idle
        syncError = nil
        bestStreak = nil
        currentPlayerId = nil
        savedName = nil
        savedPlayedAt = nil
        objectWillChange.send()
    }

    func setDifficulty(_ level: DifficultyLevel) async {
        await game.setDifficulty(level)
        objectWillChange.send()
    }

    func playTurn(row: Int, col: Int) async {
        await game.playTurn(Position(row, col))
        objectWillChange.send()
    }

    func saveGame(name: String) async {
        guard let playerRepo = playerRepository, let gameRepo = gameRepository else {
            syncState = .error
            syncError = "Database unavailable"
            return
        }

        syncState = .saving

        guard let playerId = await playerRepo.getOrCreatePlayer(name: name) else {
            syncState = .error
            syncError = "Failed to get player"
            return
        }

        currentPlayerId = playerId
        savedName = name
        savedPlayedAt = ISO8601DateFormatter().string(from: Date())

        let record = GameRecord(
            playerId: playerId,
            won: game.state.humanWon,
            difficulty: game.state.difficulty.rawValue,
            duration: Int(game.state.duration * 1000),
            playedAt: savedPlayedAt!
        )

        await gameRepo.save(record)

        let streak = await gameRepo.getStreak(for: playerId)
        currentStreak = streak.current
        bestStreak = streak.best

        syncState = .saved
    }

    func sendToServer(email: String) async {
        guard syncState == .saved || syncState == .error else { return }
        guard !email.isEmpty else {
            syncError = "Please enter email"
            return
        }
        guard let name = savedName, let playedAt = savedPlayedAt else {
            syncError = "No saved game data"
            return
        }

        syncState = .sending
        syncError = nil

        let payload = GamePayload(
            email: email,
            playerName: name,
            won: game.state.humanWon,
            difficulty: game.state.difficulty.rawValue,
            duration: Int(game.state.duration * 1000),
            playedAt: playedAt,
            streak: currentStreak
        )

        if let error = await apiService.send(payload) {
            syncState = .error
            syncError = error
        } else {
            syncState = .sent
        }
    }
}
