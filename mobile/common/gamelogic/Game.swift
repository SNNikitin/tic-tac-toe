import Foundation

public actor AI {
    private var maxDepth: Int

    public init(_ difficulty: DifficultyLevel = .medium) {
        maxDepth = Self.depth(for: difficulty)
    }

    public func setDifficulty(_ difficulty: DifficultyLevel) {
        maxDepth = Self.depth(for: difficulty)
    }

    private static func depth(for difficulty: DifficultyLevel) -> Int {
        switch difficulty { 
            case .easy: 0; 
            case .medium: 2; 
            case .hard: 9 
        }
    }

    public func bestPosition(for board: GameBoard, as player: Player) -> Position? {
        let moves = board.emptyPositions()
        if moves.isEmpty { return nil }
        if maxDepth == 0 { return moves.randomElement() }
        return search(board, player)
    }

    private func search(_ board: GameBoard, _ player: Player) -> Position? {
        var bestMove: Position?
        var bestVal = Int.min
        for move in board.emptyPositions() {
            let val = minimax(board.withMark(at: move, by: player), maxDepth - 1, false, Int.min, Int.max, player)
            if val > bestVal {
                bestVal = val
                bestMove = move
            }
        }
        return bestMove
    }

    private func minimax(_ board: GameBoard, _ depth: Int, _ maximizing: Bool, _ alpha: Int, _ beta: Int, _ aiPlayer: Player) -> Int {
        if let winResult = board.winner() {
            return winResult.player == aiPlayer ? 10 + depth : -10 - depth
        }
        if board.isFull || depth <= 0 { return 0 }

        var currentAlpha = alpha, currentBeta = beta
        let currentPlayer = maximizing ? aiPlayer : aiPlayer.opponent

        if maximizing {
            var bestScore = Int.min
            for move in board.emptyPositions() {
                bestScore = max(bestScore, minimax(board.withMark(at: move, by: currentPlayer), depth - 1, false, currentAlpha, currentBeta, aiPlayer))
                currentAlpha = max(currentAlpha, bestScore)
                if currentBeta <= currentAlpha { break }
            }
            return bestScore
        } else {
            var bestScore = Int.max
            for move in board.emptyPositions() {
                bestScore = min(bestScore, minimax(board.withMark(at: move, by: currentPlayer), depth - 1, true, currentAlpha, currentBeta, aiPlayer))
                currentBeta = min(currentBeta, bestScore)
                if currentBeta <= currentAlpha { break }
            }
            return bestScore
        }
    }
}

@MainActor
public final class Game: ObservableObject {
    @Published public private(set) var state: GameState
    private let ai: AI

    public init(difficulty: DifficultyLevel = .medium, humanPlayer: Player = .x) {
        self.ai = AI(difficulty)
        self.state = GameState(difficulty: difficulty, humanPlayer: humanPlayer)
    }

    public func newGame() {
        state = GameState(difficulty: state.difficulty, humanPlayer: state.humanPlayer)
    }

    public func setDifficulty(_ level: DifficultyLevel) async {
        await ai.setDifficulty(level)
        state.difficulty = level
    }

    public func playTurn(_ pos: Position) async -> Result<GameState, TurnError> {
        if state.isGameOver { return .failure(.gameOver) }
        if !state.isHumanTurn { return .failure(.notYourTurn) }
        if state.board[pos] != nil { return .failure(.occupied) }

        state = state.after(pos, by: state.humanPlayer)

        if state.isComputerTurn, let aiPos = await ai.bestPosition(for: state.board, as: state.computerPlayer) {
            state = state.after(aiPos, by: state.computerPlayer)
        }

        return .success(state)
    }
}
