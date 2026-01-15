import SwiftUI

extension Color {
    static let accent = Color(hex: 0x007AFF)
    static let danger = Color(hex: 0xFF3B30)
    static let success = Color(hex: 0x34C759)
    static let warning = Color(hex: 0xFF9500)
    static let grid = Color(hex: 0x333333)
    static let separator = Color(hex: 0xEEEEEE)
    static let secondaryText = Color(hex: 0x666666)
    static let disabled = Color(hex: 0xCCCCCC)
    static let winningCell = Color(hex: 0xD4EDDA)

    init(hex: UInt) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
