import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case darkCyan
    case darkDefault
    case lightCoral
    case spectatorDark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .darkCyan: return "Dark Cyan"
        case .darkDefault: return "Dark Default"
        case .lightCoral: return "Light Coral"
        case .spectatorDark: return "Spectator Dark"
        }
    }

    var accentColor: Color {
        switch self {
        case .darkCyan: return Color(hex: "00BCD4")
        case .darkDefault: return .blue
        case .lightCoral: return Color(hex: "FF6B4A")
        case .spectatorDark: return .mint
        }
    }

    var backgroundColor: Color {
        switch self {
        case .darkCyan: return Color(.sRGB, red: 0.06, green: 0.12, blue: 0.14, opacity: 1)
        case .darkDefault: return Color(.sRGB, red: 0.08, green: 0.08, blue: 0.10, opacity: 1)
        case .lightCoral: return Color(.sRGB, red: 0.98, green: 0.95, blue: 0.93, opacity: 1)
        case .spectatorDark: return Color(.sRGB, red: 0.05, green: 0.08, blue: 0.07, opacity: 1)
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .lightCoral: return .light
        default: return .dark
        }
    }
}

final class ThemeManager: ObservableObject {
    @AppStorage("selectedTheme") private var storedTheme = AppTheme.darkDefault.rawValue
    @Published var selectedTheme: AppTheme = .darkDefault {
        didSet { storedTheme = selectedTheme.rawValue }
    }

    init() {
        selectedTheme = AppTheme(rawValue: storedTheme) ?? .darkDefault
    }
}

extension Color {
    init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&int)

        let r, g, b: UInt64
        switch clean.count {
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (255, 255, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
