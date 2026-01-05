import Foundation

#if canImport(React)
import React
import Network

@objc(Network)
public class RNNetwork: NSObject {
    private var url: String?

    @objc static func moduleName() -> String { "Network" }

    @objc static func requiresMainQueueSetup() -> Bool { false }

    @objc func configure(_ url: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        self.url = url
        resolve([:])
    }

    @objc func send(_ email: String, playerName: String, won: Bool, difficulty: String, duration: Double, playedAt: String, streak: Double, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        guard let url = url else {
            resolve(["error": "Not configured"])
            return
        }
        if #available(iOS 15.0, *) {
            Task {
                let payload = Payload(email: email, playerName: playerName, won: won,
                                      difficulty: difficulty, duration: Int(duration),
                                      playedAt: playedAt, streak: Int(streak))
                if let error = await send(to: url, payload) {
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
