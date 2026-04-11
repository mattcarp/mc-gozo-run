import SwiftUI
import CoreLocation
import MapKit
import UIKit

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

    private var launchInSpectateMode: Bool {
        CommandLine.arguments.contains("--spectate") ||
        UserDefaults.standard.bool(forKey: "launch_spectate")
    }

    var body: some Scene {
        WindowGroup {
            if launchInDemoMode {
                DemoModeView(viewModel: runTracker)
                    .environmentObject(themeManager)
                    .preferredColorScheme(themeManager.selectedTheme.colorScheme)
            } else if launchInSpectateMode {
                SpectatorDemoView(viewModel: runTracker)
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

// MARK: - Spectator Demo View (full-screen, TV-optimized)

struct SpectatorDemoView: View {
    @ObservedObject var viewModel: RunTrackerViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var liveService = LiveTrackingService(role: .spectator)

    @State private var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 36.0560, longitude: 14.2500),
        span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
    ))
    @State private var cheerSent = false
    @State private var showCheerBurst = false
    @State private var pulseRunner = true

    private var trackedRunner: TrackedRunner {
        if let liveCoord = liveService.runnerPosition {
            return TrackedRunner(
                id: "runner-1",
                name: "Mattie",
                coordinate: liveCoord,
                distanceKm: liveService.runnerDistanceKm,
                paceFormatted: liveService.runnerPace,
                lastUpdate: Date()
            )
        }
        return TrackedRunner(
            id: "runner-1",
            name: "Mattie",
            coordinate: viewModel.runnerCoordinate,
            distanceKm: viewModel.distanceMeters / 1_000,
            paceFormatted: viewModel.paceFormatted,
            lastUpdate: Date()
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $cameraPosition) {
                if !viewModel.routeCoordinates.isEmpty {
                    MapPolyline(coordinates: viewModel.routeCoordinates)
                        .stroke(themeManager.selectedTheme.accentColor.opacity(0.6), lineWidth: 3)
                }

                Annotation(trackedRunner.name, coordinate: trackedRunner.coordinate) {
                    ZStack {
                        Circle()
                            .fill(themeManager.selectedTheme.accentColor.opacity(0.3))
                            .frame(width: pulseRunner ? 44 : 26, height: pulseRunner ? 44 : 26)
                            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulseRunner)
                        Circle()
                            .fill(themeManager.selectedTheme.accentColor)
                            .frame(width: 24, height: 24)
                        Image(systemName: "figure.run")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.black)
                    }
                    .shadow(radius: 6)
                }

                ForEach(viewModel.kmMarkers) { marker in
                    Annotation("", coordinate: marker.coordinate) {
                        Text("\(marker.kilometer)")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(3)
                            .background(Circle().fill(.black.opacity(0.4)))
                    }
                }
            }
            .mapStyle(.hybrid(elevation: .realistic))
            .onChange(of: liveService.runnerPosition?.latitude) { _, _ in
                guard let pos = liveService.runnerPosition else { return }
                withAnimation(.easeInOut(duration: 1.5)) {
                    cameraPosition = .region(MKCoordinateRegion(
                        center: pos,
                        span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
                    ))
                }
            }

            VStack(spacing: 12) {
                // Header badge
                HStack {
                    HStack(spacing: 6) {
                        Text("SPECTATOR")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(themeManager.selectedTheme.accentColor)
                            .clipShape(Capsule())
                        if liveService.isConnected {
                            HStack(spacing: 4) {
                                Circle().fill(.green).frame(width: 6, height: 6)
                                Text("LIVE")
                                    .font(.system(size: 9, weight: .heavy))
                                    .foregroundStyle(.green)
                            }
                        } else {
                            HStack(spacing: 4) {
                                Circle().fill(.orange).frame(width: 6, height: 6)
                                Text("CONNECTING...")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                    Spacer()
                    Text("Il-Girja t\u{2019}G\u{0127}awdex")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)

                // Runner info card
                HStack(spacing: 16) {
                    Image(systemName: "figure.run.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(themeManager.selectedTheme.accentColor)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(trackedRunner.name)
                            .font(.title2.bold())
                        HStack(spacing: 16) {
                            Label(String(format: "%.1f km", trackedRunner.distanceKm), systemImage: "location")
                                .font(.headline)
                            Label(trackedRunner.paceFormatted, systemImage: "stopwatch")
                                .font(.headline)
                            if liveService.cheerCount > 0 {
                                Label("\(liveService.cheerCount)", systemImage: "hands.clap.fill")
                                    .font(.headline)
                                    .foregroundStyle(.yellow)
                            }
                        }
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Progress ring (larger for TV)
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.15), lineWidth: 5)
                        Circle()
                            .trim(from: 0, to: min(trackedRunner.distanceKm / 21.1, 1.0))
                            .stroke(themeManager.selectedTheme.accentColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.8), value: trackedRunner.distanceKm)
                        VStack(spacing: 1) {
                            Text(String(format: "%.0f%%", min(trackedRunner.distanceKm / 21.1 * 100, 100)))
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                            Text("done")
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 60, height: 60)
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 16)

                // Cheer button
                Button {
                    sendCheer()
                } label: {
                    HStack {
                        Image(systemName: cheerSent ? "checkmark.circle.fill" : "hands.clap.fill")
                        Text(cheerSent ? "Cheer sent!" : "Send a Cheer!")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(cheerSent ? Color.green : themeManager.selectedTheme.accentColor)
                    .foregroundStyle(cheerSent ? .white : .black)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(cheerSent)
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            liveService.connect()
            pulseRunner = true
        }
        .onDisappear { liveService.disconnect() }
    }

    private func sendCheer() {
        liveService.sendCheer(from: "Fiona")
        withAnimation(.spring(response: 0.3)) {
            cheerSent = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            withAnimation { cheerSent = false }
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
