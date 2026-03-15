import SwiftUI
import CoreLocation

@main
struct GozoRunApp: App {
    @StateObject private var runTracker = RunTrackerViewModel()
    @StateObject private var themeManager = ThemeManager()
    private let voiceAlertManager = VoiceAlertManager()

    private let raceSession: RunSession = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Malta") ?? .current
        let startDate = calendar.date(from: DateComponents(year: 2026, month: 4, day: 26, hour: 7, minute: 30)) ?? Date()

        return RunSession(
            raceName: "Gozo Half Marathon (Il-Girja t'Ghawdex)",
            startDate: startDate,
            startCoordinate: CLLocationCoordinate2D(latitude: 36.0505, longitude: 14.2678),
            totalDistanceKm: 21.1
        )
    }()

    var body: some Scene {
        WindowGroup {
            VStack(spacing: 0) {
                ContentView(runTracker: runTracker, raceSession: raceSession)

                TabView {
                    MapView(viewModel: runTracker)
                        .tabItem {
                            Label("Map", systemImage: "map")
                        }

                    SpectatorView(viewModel: runTracker)
                        .tabItem {
                            Label("Spectators", systemImage: "person.3")
                        }

                    alertsView
                        .tabItem {
                            Label("Alerts", systemImage: "bell")
                        }

                    SettingsView(viewModel: runTracker)
                        .environmentObject(themeManager)
                        .tabItem {
                            Label("Settings", systemImage: "gearshape")
                        }
                }
            }
            .preferredColorScheme(themeManager.selectedTheme.colorScheme)
            .tint(themeManager.selectedTheme.accentColor)
            .background(themeManager.selectedTheme.backgroundColor.ignoresSafeArea())
            .onAppear {
                runTracker.startTracking()
            }
            .onDisappear {
                runTracker.stopTracking()
            }
            .onChange(of: runTracker.distanceMeters) { _, distance in
                voiceAlertManager.announceSplitIfNeeded(
                    distanceMeters: distance,
                    elapsed: runTracker.elapsedTime,
                    enabled: runTracker.voiceEnabled
                )
            }
        }
    }

    private var alertsView: some View {
        NavigationStack {
            List(runTracker.kmSplits) { split in
                VStack(alignment: .leading, spacing: 4) {
                    Text("KM \(split.kilometer)")
                        .font(.headline)
                    Text("Elapsed: \(formatTime(split.elapsedTime))")
                    Text(String(format: "Avg pace: %.2f min/km", split.paceMinPerKm))
                }
            }
            .navigationTitle("Alerts")
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
