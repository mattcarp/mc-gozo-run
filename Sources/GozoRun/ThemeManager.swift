import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case limestone
    case mediterranean
    case sunset
    case terracotta

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .limestone: return "Limestone"
        case .mediterranean: return "Mediterranean"
        case .sunset: return "Sunset"
        case .terracotta: return "Terracotta"
        }
    }

    var accentColor: Color {
        switch self {
        case .limestone: return Color(hex: "00BCD4")
        case .mediterranean: return .blue
        case .sunset: return Color(hex: "FF6B4A")
        case .terracotta: return .mint
        }
    }

    var backgroundColor: Color {
        switch self {
        case .limestone: return Color(.sRGB, red: 0.06, green: 0.12, blue: 0.14, opacity: 1)
        case .mediterranean: return Color(.sRGB, red: 0.08, green: 0.08, blue: 0.10, opacity: 1)
        case .sunset: return Color(.sRGB, red: 0.98, green: 0.95, blue: 0.93, opacity: 1)
        case .terracotta: return Color(.sRGB, red: 0.05, green: 0.08, blue: 0.07, opacity: 1)
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .sunset: return .light
        default: return .dark
        }
    }
}

final class ThemeManager: ObservableObject {
    @AppStorage("selectedTheme") private var storedTheme = AppTheme.mediterranean.rawValue
    @Published var selectedTheme: AppTheme = .mediterranean {
        didSet { storedTheme = selectedTheme.rawValue }
    }

    init() {
        selectedTheme = AppTheme(rawValue: storedTheme) ?? .mediterranean
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
