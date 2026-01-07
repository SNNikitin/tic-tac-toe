import Foundation

#if canImport(React)
import React
import Network

@available(iOS 15.0, *)
private actor NetworkHolder {
    private var client: Network.NetworkClient?

    func configure(url: String) -> Bool {
        guard let created = Network.NetworkClient.create(url: url) else { return false }
        client = created
        return true
    }

    func get() -> Network.NetworkClient? {
        return client
    }
}

@objc(Network)
public class RNNetwork: NSObject {
    @available(iOS 15.0, *)
    private var holder: NetworkHolder { _holder as! NetworkHolder }
    private lazy var _holder: Any = {
        if #available(iOS 15.0, *) { return NetworkHolder() }
        return NSNull()
    }()

    @objc static func moduleName() -> String { "Network" }

    @objc static func requiresMainQueueSetup() -> Bool { false }

    @objc func configure(_ url: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        if #available(iOS 15.0, *) {
            Task {
                if await holder.configure(url: url) {
                    resolve([:])
                } else {
                    resolve(["error": "Invalid URL"])
                }
            }
        } else {
            resolve(["error": "Requires iOS 15+"])
        }
    }

    @objc func send(_ email: String, playerName: String, won: Bool, difficulty: String, duration: Double, playedAt: String, streak: Double, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        if #available(iOS 15.0, *) {
            Task {
                guard let client = await holder.get() else {
                    resolve(["error": "Not configured"])
                    return
                }
                let payload = Payload(email: email, playerName: playerName, won: won,
                                      difficulty: difficulty, duration: Int(duration),
                                      playedAt: playedAt, streak: Int(streak))
                if let error = await client.send(payload) {
                    resolve(["error": error])
                } else {
                    resolve([:])
                }
            }
        } else {
            resolve(["error": "Requires iOS 15+"])
        }
    }
}

#endif
