import Foundation
import Network

private actor NetworkHolder {
    private var client: NetworkClient?

    func configure(url: String) -> Bool {
        guard let created = NetworkClient.create(url: url) else { return false }
        client = created
        return true
    }

    func get() -> NetworkClient? {
        return client
    }
}

@objcMembers
public class NetworkBridge: NSObject, @unchecked Sendable {
    private let holder = NetworkHolder()
    private let queue = DispatchQueue.main

    public func configure(url: String, resolve: @escaping ResolveBlock, reject: @escaping RejectBlock) {
        Task { [self, resolve] in
            if await holder.configure(url: url) {
                queue.async { resolve([:]) }
            } else {
                queue.async { resolve(["error": "Invalid URL"]) }
            }
        }
    }

    public func send(email: String, playerName: String, won: Bool, difficulty: String, duration: Double, playedAt: String, streak: Double, resolve: @escaping ResolveBlock, reject: @escaping RejectBlock) {
        Task { [self, resolve] in
            guard let client = await holder.get() else {
                queue.async { resolve(["error": "Not configured"]) }
                return
            }
            let payload = Payload(email: email, playerName: playerName, won: won,
                                  difficulty: difficulty, duration: Int(duration),
                                  playedAt: playedAt, streak: Int(streak))
            if let error = await client.send(payload) {
                queue.async { resolve(["error": error]) }
            } else {
                queue.async { resolve([:]) }
            }
        }
    }
}
