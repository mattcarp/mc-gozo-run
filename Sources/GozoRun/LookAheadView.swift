import SwiftUI
import MapKit

struct LookAheadView: View {
    @ObservedObject var viewModel: RunTrackerViewModel
    @EnvironmentObject var themeManager: ThemeManager

    @State private var lookAroundScene: MKLookAroundScene?
    @State private var isLoading = false
    @State private var noDataAvailable = false
    @State private var isExpanded = false

    private let lookAheadMeters: Double = 500

    var body: some View {
        VStack(spacing: 0) {
            // Toggle button
            Button {
                withAnimation(.spring(response: 0.4)) {
                    isExpanded.toggle()
                }
                if isExpanded {
                    Task { await loadLookAhead() }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "binoculars.fill")
                    Text("Look Ahead")
                        .font(.caption.bold())
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.6)
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(themeManager.selectedTheme.accentColor.opacity(0.85))
                .clipShape(Capsule())
            }

            if isExpanded {
                Group {
                    if let scene = lookAroundScene {
                        LookAroundPreview(initialScene: scene)
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(themeManager.selectedTheme.accentColor.opacity(0.4), lineWidth: 1)
                            )
                            .overlay(alignment: .bottomLeading) {
                                Text("500m ahead")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.black.opacity(0.6))
                                    .clipShape(Capsule())
                                    .padding(8)
                            }
                    } else if noDataAvailable {
                        VStack(spacing: 8) {
                            Image(systemName: "eye.slash")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            Text("No street view for this stretch")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Keep running — views ahead!")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onChange(of: viewModel.runnerCoordinate.latitude) { _, _ in
            if isExpanded {
                Task { await loadLookAhead() }
            }
        }
    }

    private func loadLookAhead() async {
        isLoading = true
        noDataAvailable = false

        let aheadCoord = findPointAhead(meters: lookAheadMeters)
        let request = MKLookAroundSceneRequest(coordinate: aheadCoord)

        do {
            let scene = try await request.scene
            await MainActor.run {
                self.lookAroundScene = scene
                self.noDataAvailable = (scene == nil)
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.lookAroundScene = nil
                self.noDataAvailable = true
                self.isLoading = false
            }
        }
    }

    private func findPointAhead(meters: Double) -> CLLocationCoordinate2D {
        let coords = viewModel.routeCoordinates
        guard !coords.isEmpty else { return viewModel.runnerCoordinate }

        let runnerLoc = CLLocation(latitude: viewModel.runnerCoordinate.latitude,
                                    longitude: viewModel.runnerCoordinate.longitude)

        var closestIdx = 0
        var closestDist = Double.greatestFiniteMagnitude
        for (i, c) in coords.enumerated() {
            let d = runnerLoc.distance(from: CLLocation(latitude: c.latitude, longitude: c.longitude))
            if d < closestDist {
                closestDist = d
                closestIdx = i
            }
        }

        var accumulated: Double = 0
        for i in closestIdx..<(coords.count - 1) {
            let a = CLLocation(latitude: coords[i].latitude, longitude: coords[i].longitude)
            let b = CLLocation(latitude: coords[i+1].latitude, longitude: coords[i+1].longitude)
            accumulated += a.distance(from: b)
            if accumulated >= meters {
                return coords[i+1]
            }
        }

        return coords.last ?? viewModel.runnerCoordinate
    }
}
