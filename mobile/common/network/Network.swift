import Foundation

public struct Payload: Codable {
    public let email: String
    public let playerName: String
    public let won: Bool
    public let difficulty: String
    public let duration: Int
    public let playedAt: String
    public let streak: Int
}

@available(iOS 15.0, macOS 12.0, *)
public func send(to url: String, _ payload: Payload) async -> String? {
    guard let url = URL(string: url) else { return "Invalid URL" }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    do {
        request.httpBody = try JSONEncoder().encode(payload)
    } catch {
        print("[Network] Encoding error: \(error.localizedDescription)")
        return "Encoding error: \(error.localizedDescription)"
    }

    do {
        let (_, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            print("[Network] Server error: HTTP \(httpResponse.statusCode)")
            return "Server error: HTTP \(httpResponse.statusCode)"
        }
        return nil
    } catch {
        print("[Network] Request error: \(error.localizedDescription)")
        return error.localizedDescription
    }
}
