import Foundation

public enum Player: Int {
    case x = 1, o = -1
    var opponent: Player { self == .x ? .o : .x }
}

public struct Position: Equatable {
    public var row: Int
    public var col: Int
    public init(_ row: Int, _ col: Int) {
        self.row = row
        self.col = col
    }
}

public enum DifficultyLevel: String { case easy, medium, hard }

public enum GameResult: String {
    case inProgress, xWins, oWins, draw
    var isFinished: Bool { self != .inProgress }
    var winner: Player? {
        if self == .xWins { return .x }
        if self == .oWins { return .o }
        return nil
    }
}

public enum TurnError: Error { case occupied, gameOver, notYourTurn }

public struct GameBoard: Equatable {
    public var cells: [[Player?]] = Array(repeating: Array(repeating: nil, count: 3), count: 3)

    subscript(_ position: Position) -> Player? {
        get {
            guard (0..<3).contains(position.row) && (0..<3).contains(position.col) else { return nil }
            return cells[position.row][position.col]
        }
        set {
            if (0..<3).contains(position.row) && (0..<3).contains(position.col) {
                cells[position.row][position.col] = newValue
            }
        }
    }

    func emptyPositions() -> [Position] {
        (0..<3).flatMap { row in (0..<3).compactMap { col in cells[row][col] == nil ? Position(row, col) : nil } }
    }

    func withMark(at pos: Position, by player: Player) -> GameBoard {
        var board = self
        board[pos] = player
        return board
    }

    var isFull: Bool { cells.allSatisfy { $0.allSatisfy { $0 != nil } } }

    var turnCount: Int { cells.flatMap { $0 }.count { $0 != nil } }

    private static let winLines: [[Position]] = [
        // rows
        [Position(0, 0), Position(0, 1), Position(0, 2)],
        [Position(1, 0), Position(1, 1), Position(1, 2)],
        [Position(2, 0), Position(2, 1), Position(2, 2)],
        // cols
        [Position(0, 0), Position(1, 0), Position(2, 0)],
        [Position(0, 1), Position(1, 1), Position(2, 1)],
        [Position(0, 2), Position(1, 2), Position(2, 2)],
        // diagonals
        [Position(0, 0), Position(1, 1), Position(2, 2)],
        [Position(0, 2), Position(1, 1), Position(2, 0)]
    ]

    func winner() -> (player: Player, line: [Position])? {
        for line in Self.winLines {
            let players = line.compactMap { self[$0] }
            if players.count == 3 && players.dropFirst().allSatisfy({ $0 == players[0] }) {
                return (players[0], line)
            }
        }
        return nil
    }

    var result: GameResult {
        if let winResult = winner() { return winResult.player == .x ? .xWins : .oWins }
        return isFull ? .draw : .inProgress
    }
}

public struct GameState: Equatable {
    public var board = GameBoard()
    public var currentPlayer: Player = .x
    public var difficulty: DifficultyLevel
    public var humanPlayer: Player
    public var startedAt = Date()

    public init(difficulty: DifficultyLevel = .medium, humanPlayer: Player = .x) {
        self.difficulty = difficulty
        self.humanPlayer = humanPlayer
    }

    var computerPlayer: Player { humanPlayer.opponent }
    var result: GameResult { board.result }
    var isGameOver: Bool { result.isFinished }
    var turnCount: Int { board.turnCount }
    var isHumanTurn: Bool { currentPlayer == humanPlayer && !isGameOver }
    var isComputerTurn: Bool { currentPlayer == computerPlayer && !isGameOver }
    var winningLine: [Position]? { board.winner()?.line }
    var duration: TimeInterval { Date().timeIntervalSince(startedAt) }

    var outcomeForHuman: String? {
        switch result {
            case .xWins: return humanPlayer == .x ? "win" : "loss"
            case .oWins: return humanPlayer == .o ? "win" : "loss"
            case .draw: return "draw"
            case .inProgress: return nil
        }
    }

    func after(_ pos: Position, by player: Player) -> GameState {
        var newState = self
        newState.board = board.withMark(at: pos, by: player)
        newState.currentPlayer = player.opponent
        return newState
    }
}
