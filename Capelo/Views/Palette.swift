import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}

enum Palette {
    static let blueGray  = Color(hex: "#395C7D")
    static let silver    = Color(hex: "#AAB7BF")
    static let orangeRed = Color(hex: "#ED3F1C")
    static let cream     = Color(hex: "#E8E2D9")
    static let espresso  = Color(hex: "#261201")
    static let warmBlack = Color(hex: "#1C1712")
    static let sand      = Color(hex: "#D9D2C6")
    static let olive     = Color(hex: "#66801E")

    static func background(for scheme: ColorScheme) -> Color {
        cream
    }

    static func text(for scheme: ColorScheme) -> Color {
        scheme == .dark ? sand : espresso
    }
}
