import SwiftUI
import MapKit
import CoreLocation
import UIKit

// MARK: - Spectator Session Model

/// A lightweight runner record shared via CloudKit / local broadcast.
/// For v1 we use a local MultipeerConnectivity-free approach:
/// the runner's position is stored in UserDefaults with a shared App Group,
/// or — for the MVP — spectators simply see the same ViewModel (same device demo).
struct TrackedRunner: Identifiable {
    let id: String
    let name: String
    var coordinate: CLLocationCoordinate2D
    var distanceKm: Double
    var paceFormatted: String
    var lastUpdate: Date
}

// MARK: - SpectatorView

struct SpectatorView: View {
    @ObservedObject var viewModel: RunTrackerViewModel
    @EnvironmentObject var themeManager: ThemeManager

    // For MVP, the "tracked runner" is derived directly from the shared ViewModel.
    // When CloudKit backend is wired: replace this with a @StateObject SpectatorManager.
    private var trackedRunner: TrackedRunner {
        TrackedRunner(
            id: "runner-1",
            name: "Runner",
            coordinate: viewModel.runnerCoordinate,
            distanceKm: viewModel.distanceMeters / 1_000,
            paceFormatted: viewModel.paceFormatted,
            lastUpdate: Date()
        )
    }

    @State private var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 36.0560, longitude: 14.2500),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    ))
    @State private var cheerSent = false
    @State private var showCheerConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Map with runner dot + route
                Map(position: $cameraPosition) {
                    if !viewModel.routeCoordinates.isEmpty {
                        MapPolyline(coordinates: viewModel.routeCoordinates)
                            .stroke(themeManager.selectedTheme.accentColor.opacity(0.6), lineWidth: 3)
                    }

                    Annotation(trackedRunner.name, coordinate: trackedRunner.coordinate) {
                        ZStack {
                            Circle()
                                .fill(themeManager.selectedTheme.accentColor)
                                .frame(width: 22, height: 22)
                            Image(systemName: "figure.run")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.black)
                        }
                        .shadow(radius: 4)
                    }

                    // KM markers (subtle)
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
                .onChange(of: viewModel.runnerCoordinate.latitude) { _, _ in
                    withAnimation(.easeInOut(duration: 1.0)) {
                        cameraPosition = .region(MKCoordinateRegion(
                            center: viewModel.runnerCoordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                        ))
                    }
                }

                // Runner info card
                VStack(spacing: 12) {
                    // Runner card
                    HStack(spacing: 16) {
                        Image(systemName: "figure.run.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(themeManager.selectedTheme.accentColor)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(trackedRunner.name)
                                .font(.headline)
                            HStack(spacing: 12) {
                                Label(String(format: "%.1f km", trackedRunner.distanceKm), systemImage: "location")
                                    .font(.subheadline)
                                Label(trackedRunner.paceFormatted, systemImage: "stopwatch")
                                    .font(.subheadline)
                            }
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // Progress ring
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.15), lineWidth: 4)
                            Circle()
                                .trim(from: 0, to: min(trackedRunner.distanceKm / 21.1, 1.0))
                                .stroke(themeManager.selectedTheme.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            Text(String(format: "%.0f%%", min(trackedRunner.distanceKm / 21.1 * 100, 100)))
                                .font(.system(size: 11, weight: .bold))
                        }
                        .frame(width: 48, height: 48)
                    }
                    .padding(16)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Cheer button
                    Button {
                        sendCheer()
                    } label: {
                        HStack {
                            Image(systemName: cheerSent ? "checkmark.circle.fill" : "hands.clap.fill")
                            Text(cheerSent ? "Cheer sent! 🎉" : "Send a Cheer! 👏")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(cheerSent ? Color.green : themeManager.selectedTheme.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(cheerSent)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .navigationTitle("Spectator Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation {
                            cameraPosition = .region(MKCoordinateRegion(
                                center: viewModel.runnerCoordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                            ))
                        }
                    } label: {
                        Image(systemName: "location.fill")
                    }
                }
            }
        }
    }

    private func sendCheer() {
        // MVP: local feedback + haptic. Backend: post to CloudKit → push to runner.
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()
        withAnimation(.spring(response: 0.3)) {
            cheerSent = true
        }
        // Reset after 5s so they can cheer again
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            withAnimation { cheerSent = false }
        }
    }
}
