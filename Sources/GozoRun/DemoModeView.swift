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
    @State private var lookAroundScene: MKLookAroundScene?
    @State private var showLookAround = false
    @State private var currentKm = 0
    @State private var demoElapsed: TimeInterval = 0
    @State private var demoPace = "5:42 /km"

    private let speechSynth = AVSpeechSynthesizer()
    private let lookAroundInterval = 15  // show Look Around every N points
    private let pointDelay: TimeInterval = 0.8  // seconds between GPS points (fast for demo)

    var body: some View {
        ZStack {
            // Map background
            Map {
                if !viewModel.routeCoordinates.isEmpty {
                    MapPolyline(coordinates: viewModel.routeCoordinates)
                        .stroke(themeManager.selectedTheme.accentColor, lineWidth: 4)
                }
                Annotation("Mattie", coordinate: viewModel.runnerCoordinate) {
                    ZStack {
                        Circle().fill(.red).frame(width: 20, height: 20)
                        Circle().stroke(.white, lineWidth: 3).frame(width: 20, height: 20)
                    }
                    .shadow(color: .red.opacity(0.5), radius: 8)
                }
            }
            .mapStyle(.hybrid(elevation: .realistic))

            // Overlay HUD
            VStack {
                // Title bar
                HStack {
                    VStack(alignment: .leading) {
                        Text("DEMO MODE")
                            .font(.caption.bold())
                            .foregroundStyle(themeManager.selectedTheme.accentColor)
                        Text("Il-Girja t\u{2019}G\u{0127}awdex")
                            .font(.headline)
                    }
                    Spacer()
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

                // Look Around preview (slides in periodically)
                if showLookAround, let scene = lookAroundScene {
                    LookAroundPreview(initialScene: scene)
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

                // Stats bar
                HStack(spacing: 0) {
                    demoStat("Distance", value: String(format: "%.1f km", Double(demoIndex) * 0.032))
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

                // Start / pause button
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
    }

    // MARK: - Demo control

    private func startDemo() {
        demoRunning = true
        let coords = viewModel.routeCoordinates
        guard !coords.isEmpty else { return }

        speak("Starting demo. Running the Gozo Half Marathon. Let's go Mattie!")

        demoTimer = Timer.scheduledTimer(withTimeInterval: pointDelay, repeats: true) { _ in
            guard demoIndex < coords.count else {
                stopDemo()
                speak("Race complete! Twenty-one point one kilometres through beautiful Gozo!")
                return
            }

            viewModel.runnerCoordinate = coords[demoIndex]
            demoElapsed += 10.85  // simulated seconds per point (~2hrs / 664 points)

            let newKm = Int(Double(demoIndex) * 21.1 / Double(coords.count))
            if newKm > currentKm {
                currentKm = newKm
                let paces = ["5:42", "5:38", "5:45", "5:31", "5:55", "5:40", "5:33", "5:48", "5:36", "5:44",
                              "5:50", "5:35", "5:41", "5:39", "5:52", "5:37", "5:46", "5:43", "5:34", "5:49", "5:40"]
                demoPace = (currentKm <= paces.count) ? "\(paces[currentKm - 1]) /km" : "5:42 /km"
                speak("Kilometre \(currentKm). Pace \(demoPace.replacingOccurrences(of: " /km", with: " per kilometre")).")
            }

            // Show Look Around every N points
            if demoIndex % lookAroundInterval == 0 && demoIndex > 0 {
                Task { await loadLookAroundForDemo(at: coords[min(demoIndex + 20, coords.count - 1)]) }
            }

            demoIndex += 1
        }
    }

    private func pauseDemo() {
        demoRunning = false
        demoTimer?.invalidate()
    }

    private func stopDemo() {
        demoRunning = false
        demoTimer?.invalidate()
        demoTimer = nil
    }

    // MARK: - Look Around

    private func loadLookAroundForDemo(at coord: CLLocationCoordinate2D) async {
        let request = MKLookAroundSceneRequest(coordinate: coord)
        do {
            if let scene = try await request.scene {
                await MainActor.run {
                    self.lookAroundScene = scene
                    withAnimation(.easeInOut(duration: 0.6)) { self.showLookAround = true }
                }
                try? await Task.sleep(nanoseconds: 5_000_000_000)  // show for 5s
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.4)) { self.showLookAround = false }
                }
            }
        } catch { }
    }

    // MARK: - Speech

    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.48
        utterance.volume = 1.0
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        speechSynth.speak(utterance)
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
