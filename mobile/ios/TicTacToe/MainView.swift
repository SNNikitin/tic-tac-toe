import SwiftUI
import GameLogic
import Database
import Network

private nonisolated(unsafe) let isoFormatter = ISO8601DateFormatter()
private let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "dd.MM.yyyy"
    return f
}()

struct BestStreakInfo {
    let count: Int
    let startDate: String
    let endDate: String

    var formatted: String {
        "\(count) wins (\(formatDate(startDate)) - \(formatDate(endDate)))"
    }

    private func formatDate(_ iso: String) -> String {
        guard let date = isoFormatter.date(from: iso) else { return iso }
        return dateFormatter.string(from: date)
    }
}

enum Modal: Identifiable {
    case name
    case email(name: String, streak: Int)
    case result(title: String, message: String)

    var id: String {
        switch self {
        case .name: "name"
        case .email: "email"
        case .result: "result"
        }
    }
}

struct MainView: View {
    @StateObject private var game = Game()
    @State private var bestStreak: BestStreakInfo?
    @State private var modal: Modal?

    private let db = GameDatabase.open()
    private let api = NetworkClient.create(url: "http://snnikitin.work:3000/api/games")

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DifficultyPicker(
                    difficulty: game.state.difficulty,
                    locked: game.state.board.cells.contains { $0.contains { $0 != nil } },
                    onChange: { level in
                        Task {
                            await game.setDifficulty(level)
                            resetGame()
                        }
                    }
                )
                .padding(.top, 16)
                .padding(.bottom, 32)

                BoardView(
                    board: game.state.board,
                    winningLine: game.state.winningLine,
                    result: game.state.result,
                    onTap: { row, col in
                        Task {
                            await game.playTurn(Position(row, col))
                            if game.state.result != nil {
                                modal = .name
                            }
                        }
                    }
                )
                .allowsHitTesting(game.state.result == nil)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .navigationBarTitle("Tic-Tac-Toe (iOS)", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("New Game") { resetGame() }
                    .font(.system(size: 14))
                    .foregroundColor(.green)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink("Leaderboard") {
                        LeaderboardView(db: db)
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                }
            }
        }
        .sheet(item: $modal) { sheet in
            switch sheet {
            case .name:
                InputModalView(
                    title: "Save result?",
                    placeholder: "Input your name",
                    buttonText: "Save",
                    keyboardType: .default,
                    onSubmit: { name in
                        Task {
                            let streak = await saveGame(name: name)
                            modal = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                modal = .email(name: name, streak: streak)
                            }
                        }
                    },
                    onCancel: resetGame
                )
                .presentationDetents([.height(190)])

            case .email(let name, let streak):
                InputModalView(
                    title: "Send result to server?",
                    placeholder: "your@email.com",
                    buttonText: "Send",
                    keyboardType: .emailAddress,
                    validate: { $0.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) != nil },
                    onSubmit: { email in
                        Task {
                            modal = nil
                            
                            let err = await sendToServer(email: email, name: name, streak: streak)
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                if let err {
                                    modal = .result(title: "Error", message: err)
                                } else {
                                    modal = .result(title: "Success", message: "Result saved and sent!")
                                }
                            }
                        }
                    }
                )
                .presentationDetents([.height(190)])

            case .result(let title, let message):
                AlertModalView(title: title, message: message) {
                    modal = nil
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        resetGame()
                    }
                }
                .presentationDetents([.height(160)])
            }
        }
    }

    private func saveGame(name: String) async -> Int {
        let playerId = await db!.getPlayerId(name: name)!

        await db!.saveGame(
            playerId: playerId,
            won: game.state.result == .win,
            difficulty: game.state.difficulty.rawValue,
            duration: Int(game.state.duration * 1000),
            playedAt: isoFormatter.string(from: Date())
        )

        let streak = await db!.getCurrentStreak(for: playerId)
        if let best = await db!.getBestStreak(for: playerId), best.count > 0 {
            bestStreak = BestStreakInfo(count: best.count, startDate: best.startDate, endDate: best.endDate)
        }

        return streak
    }

    private func resetGame() {
        game.newGame()
        bestStreak = nil
    }

    private func sendToServer(email: String, name: String, streak: Int) async -> String? {
        let payload = Payload(
            email: email,
            playerName: name,
            won: game.state.result == .win,
            difficulty: game.state.difficulty.rawValue,
            duration: Int(game.state.duration * 1000),
            playedAt: isoFormatter.string(from: Date()),
            streak: streak
        )

        return await api?.send(payload)
    }
}

struct DifficultyPicker: View {
    let difficulty: DifficultyLevel
    let locked: Bool
    let onChange: (DifficultyLevel) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text("Difficulty:")
                .font(.system(size: 16))

            HStack(spacing: 8) {
                ForEach([DifficultyLevel.easy, .medium, .hard], id: \.rawValue) { level in
                    if !locked || difficulty == level {
                        Button(action: { onChange(level) }) {
                            Text(level.rawValue.capitalized)
                                .font(.system(size: 14))
                                .foregroundStyle(difficulty == level ? .white : Color.accent)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(difficulty == level ? Color.accent : .clear)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.accent, lineWidth: 1)
                                )
                        }
                        .disabled(locked)
                    }
                }
            }
        }
    }
}

struct InputModalView: View {
    let title: String
    let placeholder: String
    let buttonText: String
    let keyboardType: UIKeyboardType
    var validate: ((String) -> Bool)?
    let onSubmit: (String) -> Void
    var onCancel: (() -> Void)?

    @State private var value = ""
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) private var dismiss

    private var isValid: Bool {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return false }
        if let validate { return validate(trimmed) }
        return true
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text(title).font(.system(size: 17, weight: .semibold))
                HStack {
                    Button("Cancel") { dismiss(); onCancel?() }
                        .foregroundStyle(Color.accent)
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)

            TextField(placeholder, text: $value)
                .textFieldStyle(.roundedBorder)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isFocused)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)

            Button(action: {
                dismiss()
                onSubmit(value.trimmingCharacters(in: .whitespaces))
            }) {
                Text(buttonText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isValid ? Color.accent : Color.disabled)
                    .cornerRadius(8)
            }
            .disabled(!isValid)
            .padding(.horizontal, 16)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { isFocused = true }
        }
    }
}

struct AlertModalView: View {
    let title: String
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .padding(.top, 16)
                .padding(.bottom, 12)

            Text(message)
                .font(.system(size: 15))
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .padding(.horizontal, 16)
                .padding(.bottom, 24)

            Button("OK") { onDismiss() }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.accent)
            .foregroundStyle(.white)
            .cornerRadius(8)
            .padding(.horizontal, 16)
        }
    }
}
