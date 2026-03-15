import SwiftUI
import Charts
import CoreLocation

/// Elevation profile chart derived from GPX track points.
/// Requires the track points to have been loaded into RunTrackerViewModel.
struct ElevationChartView: View {
    @ObservedObject var viewModel: RunTrackerViewModel
    @EnvironmentObject var themeManager: ThemeManager

    @State private var isExpanded = false

    /// Downsampled elevation profile (max 200 points for performance)
    private var elevationProfile: [ElevationPoint] {
        let coords = viewModel.routeCoordinates
        guard !coords.isEmpty else { return [] }

        // We embed elevation from the GPX into a separate cache on the ViewModel.
        // For now, derive approximate elevation using the route coords index
        // (actual elevation values are in GPXParser but not yet propagated to ViewModel).
        // This is the display skeleton — will show real data once routeElevations is wired.
        guard !viewModel.routeElevations.isEmpty else { return [] }

        let elevations = viewModel.routeElevations
        let step = max(1, elevations.count / 200)
        var result: [ElevationPoint] = []
        var distanceSoFar = 0.0

        for i in stride(from: 0, to: elevations.count, by: step) {
            if i > 0 {
                let prev = coords[min(i - step, coords.count - 1)]
                let curr = coords[min(i, coords.count - 1)]
                let loc1 = CLLocation(latitude: prev.latitude, longitude: prev.longitude)
                let loc2 = CLLocation(latitude: curr.latitude, longitude: curr.longitude)
                distanceSoFar += loc1.distance(from: loc2)
            }
            result.append(ElevationPoint(distanceKm: distanceSoFar / 1000, elevationM: elevations[i]))
        }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header / toggle
            Button {
                withAnimation(.spring(response: 0.35)) { isExpanded.toggle() }
            } label: {
                HStack {
                    Image(systemName: "mountain.2")
                        .foregroundStyle(themeManager.selectedTheme.accentColor)
                    Text("Elevation Profile")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("6m – 144m")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Group {
                    if elevationProfile.isEmpty {
                        Text("Elevation data loading…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Chart(elevationProfile) { point in
                            AreaMark(
                                x: .value("Distance (km)", point.distanceKm),
                                yStart: .value("Base", 0),
                                yEnd: .value("Elevation (m)", point.elevationM)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [themeManager.selectedTheme.accentColor.opacity(0.6),
                                             themeManager.selectedTheme.accentColor.opacity(0.05)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                            LineMark(
                                x: .value("Distance (km)", point.distanceKm),
                                y: .value("Elevation (m)", point.elevationM)
                            )
                            .foregroundStyle(themeManager.selectedTheme.accentColor)
                            .lineStyle(StrokeStyle(lineWidth: 2))

                            // Runner progress marker
                            if viewModel.isTracking {
                                let runnerKm = viewModel.distanceMeters / 1000
                                if abs(point.distanceKm - runnerKm) < 0.15 {
                                    PointMark(
                                        x: .value("Distance (km)", point.distanceKm),
                                        y: .value("Elevation (m)", point.elevationM)
                                    )
                                    .foregroundStyle(.red)
                                    .symbolSize(80)
                                }
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: 5)) { value in
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel { Text("\(value.index * 5)km").font(.system(size: 9)) }
                            }
                        }
                        .chartYAxis {
                            AxisMarks(values: [0, 50, 100, 144]) { value in
                                AxisGridLine()
                                AxisValueLabel { Text("\(value.as(Int.self) ?? 0)m").font(.system(size: 9)) }
                            }
                        }
                        .frame(height: 120)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 12)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ElevationPoint: Identifiable {
    let id = UUID()
    let distanceKm: Double
    let elevationM: Double
}
