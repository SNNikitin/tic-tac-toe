import SwiftUI
import GameLogic

struct BoardView: View {
    let board: GameBoard
    let winningLine: [Position]?
    let result: GameResult?
    let onTap: (Int, Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { col in
                        Button {
                            onTap(row, col)
                        } label: {
                            CellView(
                                player: board.cells[row][col],
                                isWinning: winningLine?.contains { $0.row == row && $0.col == col } ?? false
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(2)
        .background(Color.grid)
        .overlay {
            if let result {
                Color.white.opacity(0.85)

                Text(textFor(result))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 32)
                    .background(colorFor(result))
                    .cornerRadius(12)
            }
        }
    }

    private func textFor(_ result: GameResult) -> String {
        switch result {
        case .win: "You Won!"
        case .lose: "You Lost!"
        case .draw: "It's a Draw!"
        }
    }

    private func colorFor(_ result: GameResult) -> Color {
        switch result {
        case .win: .success
        case .lose: .danger
        case .draw: .warning
        }
    }
}

struct CellView: View {
    let player: Player?
    let isWinning: Bool

    var body: some View {
        ZStack {
            Rectangle()
                .fill(isWinning ? Color.winningCell : .white)
                .frame(width: 100, height: 100)
                .border(Color.grid, width: 1)

            if let player {
                Text(player == .x ? "X" : "O")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundStyle(player == .x ? Color.accent : Color.danger)
            }
        }
    }
}
