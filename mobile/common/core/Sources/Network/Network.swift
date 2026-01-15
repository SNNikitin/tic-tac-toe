import Foundation

public struct Payload: Codable, Sendable {
    public let email: String
    public let playerName: String
    public let won: Bool
    public let difficulty: String
    public let duration: Int
    public let playedAt: String
    public let streak: Int

    public init(email: String, playerName: String, won: Bool, difficulty: String, duration: Int, playedAt: String, streak: Int) {
        self.email = email
        self.playerName = playerName
        self.won = won
        self.difficulty = difficulty
        self.duration = duration
        self.playedAt = playedAt
        self.streak = streak
    }
}

@available(iOS 15.0, macOS 12.0, *)
public actor NetworkClient {
    private let url: URL

    private init(_ url: URL) {
        self.url = url
    }

    public static func create(url: String) -> NetworkClient? {
        guard let url = URL(string: url) else {
            print("[Network] Invalid URL: \(url)")
            return nil
        }
        return NetworkClient(url)
    }

    public func send(_ payload: Payload) async -> String? {
        var req = URLRequest(url: url, timeoutInterval: 30)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        req.httpBody = try? JSONEncoder().encode(payload)

        do {
            let (_, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                print("[Network] HTTP \(http.statusCode)")
                return "Server error: HTTP \(http.statusCode)"
            }
            return nil
        } catch {
            print("[Network] \(error.localizedDescription)")
            return error.localizedDescription
        }
    }
}
