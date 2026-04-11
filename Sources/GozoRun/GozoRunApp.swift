import SwiftUI
import CoreLocation

@main
struct GozoRunApp: App {
    @StateObject private var runTracker = RunTrackerViewModel()
    @StateObject private var themeManager = ThemeManager()

    private let raceSession: RunSession = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Malta") ?? .current
        let startDate = calendar.date(from: DateComponents(
            year: 2026, month: 4, day: 26, hour: 7, minute: 30
        )) ?? Date()
        return RunSession(
            raceName: "Gozo Half Marathon (Il-Girja t\u{2019}G\u{0127}awdex)",
            startDate: startDate,
            startCoordinate: CLLocationCoordinate2D(latitude: 36.050042, longitude: 14.264673),
            totalDistanceKm: 21.1
        )
    }()

    private var launchInDemoMode: Bool {
        CommandLine.arguments.contains("--demo") ||
        UserDefaults.standard.bool(forKey: "launch_demo")
    }

    var body: some Scene {
        WindowGroup {
            if launchInDemoMode {
                DemoModeView(viewModel: runTracker)
                    .environmentObject(themeManager)
                    .preferredColorScheme(themeManager.selectedTheme.colorScheme)
            } else {
                TabView {
                    ContentView(runTracker: runTracker, raceSession: raceSession)
                        .environmentObject(themeManager)
                        .tabItem { Label("Track", systemImage: "figure.run") }

                    SplitsView(runTracker: runTracker)
                        .environmentObject(themeManager)
                        .tabItem { Label("Splits", systemImage: "list.number") }

                    SpectatorView(viewModel: runTracker)
                        .environmentObject(themeManager)
                        .tabItem { Label("Spectate", systemImage: "eye") }

                    SettingsView(viewModel: runTracker)
                        .environmentObject(themeManager)
                        .tabItem { Label("Settings", systemImage: "gearshape") }
                }
                .tint(themeManager.selectedTheme.accentColor)
                .preferredColorScheme(themeManager.selectedTheme.colorScheme)
            }
        }
    }
}

// MARK: - Splits tab

struct SplitsView: View {
    @ObservedObject var runTracker: RunTrackerViewModel
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        NavigationStack {
            Group {
                if runTracker.kmSplits.isEmpty {
                    ContentUnavailableView(
                        "No splits yet",
                        systemImage: "figure.run.circle",
                        description: Text("Start your run to record KM splits.")
                    )
                } else {
                    List(runTracker.kmSplits) { split in
                        HStack {
                            Text("KM \(split.kilometer)")
                                .font(.headline)
                                .foregroundStyle(themeManager.selectedTheme.accentColor)
                                .frame(width: 60, alignment: .leading)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(formatTime(split.elapsedTime))
                                    .font(.system(.body, design: .monospaced))
                                Text(String(format: "%.2f min/km", split.paceMinPerKm))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("KM Splits")
        }
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}
