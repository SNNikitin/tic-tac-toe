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
            case .easy: 0    // random
            case .medium: 2  // think two steps forward
            case .hard: 9    // full
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
        if let win = board.winner() {
            return win.player == aiPlayer ? 10 + depth : -10 - depth
        }
        if board.isFull || depth <= 0 { return 0 }

        var a = alpha, b = beta
        let player = maximizing ? aiPlayer : aiPlayer.opponent

        if maximizing {
            var best = Int.min
            for move in board.emptyPositions() {
                best = max(best, minimax(board.withMark(at: move, by: player), depth - 1, false, a, b, aiPlayer))
                a = max(a, best)
                if b <= a { break }
            }
            return best
        } else {
            var best = Int.max
            for move in board.emptyPositions() {
                best = min(best, minimax(board.withMark(at: move, by: player), depth - 1, true, a, b, aiPlayer))
                b = min(b, best)
                if b <= a { break }
            }
            return best
        }
    }
}

@MainActor
public final class Game: ObservableObject {
    @Published public private(set) var state: GameState
    private let ai: AI

    public init(difficulty: DifficultyLevel = .medium) {
        self.ai = AI(difficulty)
        self.state = GameState(difficulty: difficulty)
    }

    public func newGame() {
        state = GameState(difficulty: state.difficulty)
    }

    public func setDifficulty(_ level: DifficultyLevel) async {
        await ai.setDifficulty(level)
        state.difficulty = level
    }

    public func playTurn(_ pos: Position) async {
        guard !state.isGameOver, state.currentPlayer == .x, state.board[pos] == nil else { return }

        state = state.after(pos, by: .x)

        if !state.isGameOver, let aiPos = await ai.bestPosition(for: state.board, as: .o) {
            state = state.after(aiPos, by: .o)
        }
    }
}
