import Foundation
import GameLogic

@objcMembers
public class GameBridge: NSObject {
    nonisolated(unsafe) private var game: Game?
    private let queue = DispatchQueue.main

    @MainActor private func getGame() -> Game {
        if let g = game { return g }
        let g = Game()
        game = g
        return g
    }

    public func newGame(resolve: @escaping ResolveBlock, reject: @escaping RejectBlock) {
        queue.async { [self] in
            MainActor.assumeIsolated {
                let g = getGame()
                g.newGame()
                resolve(toDict(g.state))
            }
        }
    }

    public func setDifficulty(_ level: String, resolve: @escaping ResolveBlock, reject: @escaping RejectBlock) {
        queue.async { [self] in
            MainActor.assumeIsolated {
                guard let difficulty = DifficultyLevel(rawValue: level) else {
                    reject("invalidDifficulty", "Invalid difficulty level", nil)
                    return
                }
                let g = getGame()
                Task {
                    await g.setDifficulty(difficulty)
                    resolve(self.toDict(g.state))
                }
            }
        }
    }

    public func playTurn(row: Double, col: Double, resolve: @escaping ResolveBlock, reject: @escaping RejectBlock) {
        queue.async { [self] in
            MainActor.assumeIsolated {
                let g = getGame()
                Task {
                    await g.playTurn(Position(Int(row), Int(col)))
                    resolve(self.toDict(g.state))
                }
            }
        }
    }

    private func toDict(_ state: GameState) -> [String: Any] {
        var dict: [String: Any] = [
            "board": state.board.cells.flatMap { $0.map { $0?.rawValue ?? 0 } },
            "difficulty": state.difficulty.rawValue,
            "duration": state.duration * 1000,
            "isGameOver": state.isGameOver
        ]
        if let result = state.result { dict["result"] = result.rawValue }
        if let line = state.winningLine { dict["winningLine"] = line.map { ["row": $0.row, "col": $0.col] } }
        return dict
    }
}
