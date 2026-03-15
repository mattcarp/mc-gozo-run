import SwiftUI

struct ContentView: View {
    @ObservedObject var runTracker: RunTrackerViewModel
    @EnvironmentObject var themeManager: ThemeManager
    let raceSession: RunSession

    @State private var hudExpanded = true
    @State private var showSpectator = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Full-screen map
            MapView(viewModel: runTracker)
                .ignoresSafeArea()

            // Stats HUD
            VStack(spacing: 0) {
                // Drag handle / collapse toggle
                Button {
                    withAnimation(.spring(response: 0.35)) {
                        hudExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: hudExpanded ? "chevron.down" : "chevron.up")
                            .foregroundStyle(.secondary)
                            .padding(6)
                        Spacer()
                    }
                }
                .background(themeManager.selectedTheme.backgroundColor.opacity(0.95))

                if hudExpanded {
                    VStack(spacing: 12) {
                        // Countdown / race header
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Il-Girja t'Għawdex")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("Gozo Half Marathon · 21.1 km")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(countdownText)
                                .font(.caption)
                                .foregroundStyle(themeManager.selectedTheme.accentColor)
                                .multilineTextAlignment(.trailing)
                        }

                        Divider().opacity(0.3)

                        // Stats grid
                        HStack(spacing: 0) {
                            StatCell(label: "Distance", value: runTracker.distanceFormatted)
                            Divider().frame(height: 40)
                            StatCell(label: "Time", value: runTracker.elapsedFormatted)
                            Divider().frame(height: 40)
                            StatCell(label: "Pace", value: runTracker.paceFormatted)
                            Divider().frame(height: 40)
                            StatCell(label: "Elev +", value: runTracker.elevationFormatted)
                        }

                        // Control buttons
                        HStack(spacing: 12) {
                            Button {
                                if runTracker.isTracking {
                                    runTracker.stopTracking()
                                } else {
                                    runTracker.startTracking()
                                }
                            } label: {
                                Label(
                                    runTracker.isTracking ? "Stop" : "Start",
                                    systemImage: runTracker.isTracking ? "stop.fill" : "play.fill"
                                )
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(runTracker.isTracking ? Color.red : themeManager.selectedTheme.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }

                            Button {
                                showSpectator = true
                            } label: {
                                Label("Spectate", systemImage: "eye")
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                    .padding(.top, 8)
                    .background(themeManager.selectedTheme.backgroundColor.opacity(0.95))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .preferredColorScheme(themeManager.selectedTheme.colorScheme)
        .sheet(isPresented: $showSpectator) {
            SpectatorView(viewModel: runTracker)
                .environmentObject(themeManager)
        }
    }

    // MARK: - Countdown

    private var countdownText: String {
        let now = Date()
        let diff = raceSession.startDate.timeIntervalSince(now)
        if diff <= 0 {
            return "Race is live! 🏃"
        }
        let totalSeconds = Int(diff)
        let d = totalSeconds / 86400
        let h = (totalSeconds % 86400) / 3600
        let m = (totalSeconds % 3600) / 60
        if d > 0 {
            return "\(d)d \(h)h \(m)m to race"
        }
        return "\(h)h \(m)m to start"
    }
}

// MARK: - Stat cell

private struct StatCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.subheadline, design: .monospaced).bold())
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
