import SwiftUI
import MapKit

struct MapView: View {
    @ObservedObject var viewModel: RunTrackerViewModel

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 36.0505, longitude: 14.2678),
            span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
        )
    )

    private let placeholderRoute: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 36.0505, longitude: 14.2678),
        CLLocationCoordinate2D(latitude: 36.0561, longitude: 14.2739),
        CLLocationCoordinate2D(latitude: 36.0632, longitude: 14.2686),
        CLLocationCoordinate2D(latitude: 36.0588, longitude: 14.2599),
        CLLocationCoordinate2D(latitude: 36.0505, longitude: 14.2678)
    ]

    var body: some View {
        Map(position: $cameraPosition) {
            MapPolyline(coordinates: placeholderRoute)
                .stroke(.orange, lineWidth: 5)

            Annotation("Runner", coordinate: viewModel.runnerCoordinate) {
                Circle()
                    .fill(.red)
                    .frame(width: 16, height: 16)
                    .overlay(Circle().stroke(.white, lineWidth: 2))
            }

            ForEach(viewModel.spectatorLocations) { spectator in
                Annotation(spectator.name, coordinate: spectator.coordinate) {
                    Circle()
                        .fill(.blue)
                        .frame(width: 12, height: 12)
                }
            }
        }
        .mapStyle(.hybrid(elevation: .realistic))
        .onAppear {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 36.0505, longitude: 14.2678),
                    span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
                )
            )
        }
    }
}
