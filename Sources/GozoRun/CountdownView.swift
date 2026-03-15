import SwiftUI

struct CountdownView: View {
    let raceDate: Date
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Group {
            if timeRemaining <= 0 {
                raceActiveView
            } else {
                countdownGrid
            }
        }
        .onReceive(timer) { _ in now = Date() }
    }

    // MARK: - Countdown grid

    private var countdownGrid: some View {
        HStack(spacing: 0) {
            CountdownUnit(value: days, label: "DAYS", accent: themeManager.selectedTheme.accentColor)
            separator
            CountdownUnit(value: hours, label: "HRS", accent: themeManager.selectedTheme.accentColor)
            separator
            CountdownUnit(value: minutes, label: "MIN", accent: themeManager.selectedTheme.accentColor)
            separator
            CountdownUnit(value: seconds, label: "SEC", accent: themeManager.selectedTheme.accentColor)
        }
    }

    private var separator: some View {
        Text(":")
            .font(.system(.title2, design: .monospaced).bold())
            .foregroundStyle(themeManager.selectedTheme.accentColor)
            .padding(.horizontal, 2)
    }

    private var raceActiveView: some View {
        HStack(spacing: 8) {
            Image(systemName: "figure.run")
                .foregroundStyle(themeManager.selectedTheme.accentColor)
                .symbolEffect(.bounce, options: .repeating)
            Text("Race is LIVE!")
                .font(.headline)
                .foregroundStyle(themeManager.selectedTheme.accentColor)
        }
    }

    // MARK: - Time calculations

    private var timeRemaining: TimeInterval {
        raceDate.timeIntervalSince(now)
    }

    private var totalSeconds: Int { max(0, Int(timeRemaining)) }
    private var days: Int    { totalSeconds / 86400 }
    private var hours: Int   { (totalSeconds % 86400) / 3600 }
    private var minutes: Int { (totalSeconds % 3600) / 60 }
    private var seconds: Int { totalSeconds % 60 }
}

// MARK: - CountdownUnit

private struct CountdownUnit: View {
    let value: Int
    let label: String
    let accent: Color

    var body: some View {
        VStack(spacing: 1) {
            Text(String(format: "%02d", value))
                .font(.system(.title2, design: .monospaced).bold())
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: value)
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(accent)
                .tracking(1)
        }
        .frame(minWidth: 36)
    }
}
