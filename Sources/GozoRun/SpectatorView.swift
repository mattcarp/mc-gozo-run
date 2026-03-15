import SwiftUI
import CoreLocation

struct SpectatorView: View {
    @ObservedObject var viewModel: RunTrackerViewModel

    var body: some View {
        NavigationStack {
            List(viewModel.spectatorLocations) { spectator in
                VStack(alignment: .leading, spacing: 4) {
                    Text(spectator.name)
                        .font(.headline)
                    Text(distanceText(to: spectator.coordinate))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Spectators")
        }
    }

    private func distanceText(to coordinate: CLLocationCoordinate2D) -> String {
        let runner = CLLocation(latitude: viewModel.runnerCoordinate.latitude, longitude: viewModel.runnerCoordinate.longitude)
        let spectator = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let meters = runner.distance(from: spectator)

        switch viewModel.units {
        case .metric:
            return String(format: "%.2f km from runner", meters / 1_000)
        case .imperial:
            return String(format: "%.2f mi from runner", meters / 1_609.344)
        }
    }
}
