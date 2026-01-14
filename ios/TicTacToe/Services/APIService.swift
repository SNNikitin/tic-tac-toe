import Foundation
import Network

protocol APIServiceProtocol: Sendable {
    func send(_ payload: GamePayload) async -> String?
}

final class APIService: APIServiceProtocol, @unchecked Sendable {
    private static let apiURL = "http://snnikitin.work:3000/api/games"
    private var client: NetworkClient?

    func send(_ payload: GamePayload) async -> String? {
        if client == nil {
            client = NetworkClient.create(url: Self.apiURL)
        }

        guard let client else {
            return "Invalid server URL"
        }

        let networkPayload = Payload(
            email: payload.email,
            playerName: payload.playerName,
            won: payload.won,
            difficulty: payload.difficulty,
            duration: payload.duration,
            playedAt: payload.playedAt,
            streak: payload.streak
        )

        return await client.send(networkPayload)
    }
}
