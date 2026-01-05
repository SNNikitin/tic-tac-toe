import Foundation

#if canImport(React)
import React
import GameLogic

@objc(Game)
public class RNGame: NSObject {
    @MainActor private var game = GameLogic.Game()

    @objc static func moduleName() -> String { "Game" }

    @objc static func requiresMainQueueSetup() -> Bool { true }

    @objc func newGame(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        Task { @MainActor in
            game.newGame()
            resolve(["state": toDict(game.state)])
        }
    }

    @objc func setDifficulty(_ level: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        Task { @MainActor in
            guard let difficulty = DifficultyLevel(rawValue: level) else {
                resolve(["error": "invalidDifficulty"])
                return
            }
            await game.setDifficulty(difficulty)
            resolve(["difficulty": level])
        }
    }

    @objc func playTurn(_ row: Double, col: Double, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        Task { @MainActor in
            let result = await game.playTurn(Position(Int(row), Int(col)))
            switch result {
                case .success(let state): resolve(["state": toDict(state)])
                case .failure(let error): resolve(["error": errorString(error)])
            }
        }
    }

    @objc func getState(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        Task { @MainActor in
            resolve(["state": toDict(game.state)])
        }
    }

    private func errorString(_ error: TurnError) -> String {
        switch error {
            case .occupied: return "occupied"
            case .gameOver: return "gameOver"
            case .notYourTurn: return "notYourTurn"
        }
    }

    private func toDict(_ state: GameState) -> [String: Any] {
        var dict: [String: Any] = [
            "board": state.board.cells.flatMap { $0.map { $0?.rawValue ?? 0 } },
            "currentPlayer": state.currentPlayer.rawValue,
            "result": state.result.rawValue,
            "isGameOver": state.isGameOver,
            "isHumanTurn": state.isHumanTurn,
            "isComputerTurn": state.isComputerTurn,
            "turnCount": state.turnCount,
            "difficulty": state.difficulty.rawValue,
            "humanPlayer": state.humanPlayer.rawValue,
            "computerPlayer": state.computerPlayer.rawValue,
            "startedAt": state.startedAt.timeIntervalSince1970 * 1000,
            "duration": state.duration * 1000
        ]
        if let winner = state.result.winner { dict["winner"] = winner.rawValue }
        if let line = state.winningLine { dict["winningLine"] = line.map { ["row": $0.row, "col": $0.col] } }
        if let outcome = state.outcomeForHuman { dict["outcome"] = outcome }
        return dict
    }
}

#endif
