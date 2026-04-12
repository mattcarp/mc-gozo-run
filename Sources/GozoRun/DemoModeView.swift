import SwiftUI
import MapKit
import AVFoundation
import CoreLocation

struct DemoModeView: View {
    @ObservedObject var viewModel: RunTrackerViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var demoRunning = false
    @State private var demoIndex = 0
    @State private var demoTimer: Timer?
    @State private var streetViewImage: UIImage?
    @State private var showStreetView = false
    @State private var currentKm = 0
    @State private var demoElapsed: TimeInterval = 0
    @State private var demoPace = "5:42 /km"
    @State private var demoDistanceKm: Double = 0
    @State private var showRaceComplete = false
    @State private var pulseRunner = false

    @StateObject private var liveService = LiveTrackingService(role: .runner)
    private let voiceCoach = VoiceAlertManager()
    private let lookAroundInterval = 18
    private let pointDelay: TimeInterval = 0.7

    private let simulatedPaces = [
        "5:42", "5:38", "5:45", "5:31", "5:55", "5:40", "5:33", "5:48",
        "5:36", "5:44", "5:50", "5:35", "5:41", "5:39", "5:52", "5:37",
        "5:46", "5:43", "5:34", "5:49", "5:40"
    ]

    var body: some View {
        ZStack {
            Map {
                if !viewModel.routeCoordinates.isEmpty {
                    MapPolyline(coordinates: viewModel.routeCoordinates)
                        .stroke(themeManager.selectedTheme.accentColor, lineWidth: 4)
                }
                Annotation("Mattie", coordinate: viewModel.runnerCoordinate) {
                    ZStack {
                        Circle()
                            .fill(.red.opacity(0.3))
                            .frame(width: pulseRunner ? 40 : 24, height: pulseRunner ? 40 : 24)
                            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulseRunner)
                        Circle().fill(.red).frame(width: 20, height: 20)
                        Circle().stroke(.white, lineWidth: 3).frame(width: 20, height: 20)
                        Image(systemName: "figure.run")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: .red.opacity(0.5), radius: 8)
                }
            }
            .mapStyle(.hybrid(elevation: .realistic))

            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        HStack(spacing: 6) {
                            Text("RUNNER VIEW")
                                .font(.caption.bold())
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
                            }
                        }
                        Text("Il-Girja t\u{2019}G\u{0127}awdex")
                            .font(.headline)
                    }
                    Spacer()
                    if liveService.cheerCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "hands.clap.fill")
                                .foregroundStyle(.yellow)
                            Text("\(liveService.cheerCount)")
                                .font(.subheadline.bold())
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }
                    Button("Close") { stopDemo(); dismiss() }
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.red.opacity(0.8))
                        .clipShape(Capsule())
                }
                .padding()
                .background(.ultraThinMaterial)

                Spacer()

                if showStreetView, let image = streetViewImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 16)
                        .overlay(alignment: .topLeading) {
                            HStack(spacing: 4) {
                                Image(systemName: "binoculars.fill")
                                Text("Coming up ahead...")
                                    .font(.caption.bold())
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.black.opacity(0.7))
                            .clipShape(Capsule())
                            .padding(.leading, 24)
                            .padding(.top, 8)
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                }

                HStack(spacing: 0) {
                    demoStat("Distance", value: String(format: "%.1f km", demoDistanceKm))
                    Divider().frame(height: 36)
                    demoStat("Time", value: formatDemoTime(demoElapsed))
                    Divider().frame(height: 36)
                    demoStat("Pace", value: demoPace)
                    Divider().frame(height: 36)
                    demoStat("KM", value: "\(currentKm) / 21")
                }
                .padding(.vertical, 14)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

                Button {
                    if demoRunning { pauseDemo() } else { startDemo() }
                } label: {
                    Label(
                        demoRunning ? "Pause Demo" : "Start Demo",
                        systemImage: demoRunning ? "pause.fill" : "play.fill"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(demoRunning ? .orange : themeManager.selectedTheme.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .onDisappear { stopDemo() }
        .fullScreenCover(isPresented: $showRaceComplete) {
            RaceCompleteView(
                distance: String(format: "%.2f km", demoDistanceKm),
                time: formatDemoTime(demoElapsed),
                pace: demoPace,
                elevation: "+312 m",
                cheerCount: liveService.cheerCount
            )
            .environmentObject(themeManager)
        }
    }

    // MARK: - Demo control

    private func startDemo() {
        demoRunning = true
        pulseRunner = true
        let coords = viewModel.routeCoordinates
        guard !coords.isEmpty else { return }

        liveService.connect()
        Analytics.shared.trackRaceStart(mode: "demo")
        voiceCoach.announceRaceStart()

        demoTimer = Timer.scheduledTimer(withTimeInterval: pointDelay, repeats: true) { _ in
            guard demoIndex < coords.count else {
                finishDemo()
                return
            }

            viewModel.runnerCoordinate = coords[demoIndex]

            let progress = Double(demoIndex) / Double(coords.count)
            demoDistanceKm = progress * 21.1
            demoElapsed += 10.85

            let newKm = Int(demoDistanceKm)
            if newKm > currentKm && newKm <= 21 {
                currentKm = newKm
                if currentKm <= simulatedPaces.count {
                    demoPace = "\(simulatedPaces[currentKm - 1]) /km"
                }
                voiceCoach.announceSplitIfNeeded(
                    distanceMeters: demoDistanceKm * 1000,
                    elapsed: demoElapsed,
                    enabled: true
                )
            }

            // Publish position to Supabase for spectators
            if demoIndex % 3 == 0 {
                liveService.publishPosition(
                    coordinate: coords[demoIndex],
                    distanceKm: demoDistanceKm,
                    pace: demoPace,
                    elapsed: demoElapsed
                )
            }

            if demoIndex % lookAroundInterval == 0 && demoIndex > 0 {
                let aheadIdx = min(demoIndex + 25, coords.count - 1)
                Task { await loadStreetViewForDemo(at: coords[aheadIdx], from: coords[demoIndex]) }
            }

            demoIndex += 1
        }
    }

    private func finishDemo() {
        stopDemo()
        demoDistanceKm = 21.1
        currentKm = 21
        voiceCoach.announceRaceComplete(elapsed: demoElapsed)

        Analytics.shared.trackRaceComplete(distanceKm: 21.1, elapsed: demoElapsed, avgPace: demoPace)

        liveService.publishPosition(
            coordinate: viewModel.runnerCoordinate,
            distanceKm: 21.1,
            pace: demoPace,
            elapsed: demoElapsed
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            showRaceComplete = true
        }
    }

    private func pauseDemo() {
        demoRunning = false
        demoTimer?.invalidate()
    }

    private func stopDemo() {
        demoRunning = false
        pulseRunner = false
        demoTimer?.invalidate()
        demoTimer = nil
        liveService.disconnect()
    }

    // MARK: - Street View

    private func loadStreetViewForDemo(at coord: CLLocationCoordinate2D, from runner: CLLocationCoordinate2D) async {
        let start = Date()

        // Calculate heading from runner toward the ahead point
        let dLon = (coord.longitude - runner.longitude) * .pi / 180
        let lat1 = runner.latitude * .pi / 180
        let lat2 = coord.latitude * .pi / 180
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let heading = (atan2(y, x) * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)

        // Try cache first
        if let cached = StreetViewCache.shared.image(for: coord) {
            await MainActor.run {
                self.streetViewImage = cached
                withAnimation(.easeInOut(duration: 0.6)) { self.showStreetView = true }
            }
            try? await Task.sleep(nanoseconds: 6_000_000_000)
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.4)) { self.showStreetView = false }
            }
            return
        }

        // Fetch from API
        guard let image = await StreetViewService.shared.fetchImage(
            coordinate: coord,
            heading: heading,
            size: "600x300",
            fov: 100
        ) else {
            let durationMs = Int(Date().timeIntervalSince(start) * 1000)
            Analytics.shared.trackLookAroundLoad(coordinate: coord, durationMs: durationMs, success: false)
            return
        }

        let durationMs = Int(Date().timeIntervalSince(start) * 1000)
        Analytics.shared.trackLookAroundLoad(coordinate: coord, durationMs: durationMs, success: true)
        StreetViewCache.shared.store(image: image, for: coord)

        await MainActor.run {
            self.streetViewImage = image
            withAnimation(.easeInOut(duration: 0.6)) { self.showStreetView = true }
        }
        try? await Task.sleep(nanoseconds: 6_000_000_000)
        await MainActor.run {
            withAnimation(.easeOut(duration: 0.4)) { self.showStreetView = false }
        }
    }

    // MARK: - Helpers

    private func formatDemoTime(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600
        let m = (Int(t) % 3600) / 60
        let s = Int(t) % 60
        return String(format: "%d:%02d:%02d", h, m, s)
    }

    @ViewBuilder
    private func demoStat(_ label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.subheadline, design: .monospaced).bold())
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
