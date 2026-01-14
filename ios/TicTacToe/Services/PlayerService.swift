import Foundation
import Database

protocol PlayerServiceProtocol: Sendable {
    func getOrCreatePlayer(name: String) async -> UInt?
}

final class PlayerService: PlayerServiceProtocol, @unchecked Sendable {
    private let database: GameDatabase?

    init(database: GameDatabase?) {
        self.database = database
    }

    func getOrCreatePlayer(name: String) async -> UInt? {
        await database?.getPlayerId(name: name)
    }
}
