import Foundation

public enum Player: Int, Sendable {
    case x = 1, o = -1
    var opponent: Player { self == .x ? .o : .x }
}

public struct Position: Equatable, Sendable {
    public var row: Int
    public var col: Int
    public init(_ row: Int, _ col: Int) {
        self.row = row
        self.col = col
    }
}

public enum DifficultyLevel: String, Sendable { case easy, medium, hard }
public enum GameResult: String, Sendable { case win, lose, draw }

public struct GameBoard: Equatable, Sendable {
    public var cells: [[Player?]] = Array(repeating: Array(repeating: nil, count: 3), count: 3)

    public init() {}

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

    var result: GameResult? {
        if let winResult = winner() { return winResult.player == .x ? .win : .lose }
        return isFull ? .draw : nil
    }
}

public struct GameState: Equatable, Sendable {
    public var board = GameBoard()
    public var currentPlayer: Player = .x
    public var difficulty: DifficultyLevel
    public var startedAt = Date()

    public init(difficulty: DifficultyLevel = .medium) {
        self.difficulty = difficulty
    }

    public var result: GameResult? { board.result }
    public var isGameOver: Bool { result != nil }
    public var winningLine: [Position]? { board.winner()?.line }
    public var duration: TimeInterval { Date().timeIntervalSince(startedAt) }

    func after(_ pos: Position, by player: Player) -> GameState {
        var newState = self
        newState.board = board.withMark(at: pos, by: player)
        newState.currentPlayer = player.opponent
        return newState
    }
}
