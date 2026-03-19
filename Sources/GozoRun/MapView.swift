import SwiftUI
import MapKit

struct MapView: View {
    @ObservedObject var viewModel: RunTrackerViewModel
    @EnvironmentObject var themeManager: ThemeManager

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 36.0560, longitude: 14.2500),
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
    )
    @State private var followRunner = true

    private let startCoord = CLLocationCoordinate2D(latitude: 36.050042, longitude: 14.264673)

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Map(position: $cameraPosition) {

                // Route polyline
                if !viewModel.routeCoordinates.isEmpty {
                    MapPolyline(coordinates: viewModel.routeCoordinates)
                        .stroke(themeManager.selectedTheme.accentColor, lineWidth: 4)
                }

                // Start / Finish
                Annotation("Start / Finish", coordinate: startCoord) {
                    Image(systemName: "flag.checkered")
                        .foregroundStyle(.yellow)
                        .font(.title2)
                        .background(Circle().fill(.black.opacity(0.6)).frame(width: 32, height: 32))
                }

                // KM markers
                ForEach(viewModel.kmMarkers) { marker in
                    Annotation("\(marker.kilometer)km", coordinate: marker.coordinate) {
                        ZStack {
                            Circle()
                                .fill(themeManager.selectedTheme.accentColor)
                                .frame(width: 22, height: 22)
                            Text("\(marker.kilometer)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.black)
                        }
                    }
                }

                // Water stations
                ForEach(viewModel.waterStations) { station in
                    Annotation("Water", coordinate: station.coordinate) {
                        Image(systemName: "drop.fill")
                            .foregroundStyle(.blue)
                            .font(.callout)
                            .background(Circle().fill(.white).frame(width: 22, height: 22))
                    }
                }

                // Points of Interest (toilets, first aid, parking, music, marshals, turn directions)
                ForEach(viewModel.pointsOfInterest) { poi in
                    Annotation(poi.detail.isEmpty ? poi.name : poi.detail, coordinate: poi.coordinate) {
                        poiIcon(for: poi)
                    }
                }

                // Runner dot
                Annotation("You", coordinate: viewModel.runnerCoordinate) {
                    Circle()
                        .fill(.red)
                        .frame(width: 16, height: 16)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                        .shadow(radius: 3)
                }

                // Spectators
                ForEach(viewModel.spectatorLocations) { spectator in
                    Annotation(spectator.name, coordinate: spectator.coordinate) {
                        Image(systemName: "person.fill")
                            .foregroundStyle(.white)
                            .font(.caption)
                            .background(Circle().fill(.indigo).frame(width: 22, height: 22))
                    }
                }
            }
            .mapStyle(.hybrid(elevation: .realistic))
            .onChange(of: viewModel.runnerCoordinate.latitude) { _, _ in
                if followRunner {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        cameraPosition = .region(MKCoordinateRegion(
                            center: viewModel.runnerCoordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
                        ))
                    }
                }
            }

            // POI layer toggle
            // (future: add a filter button)

            // Follow toggle
            Button {
                followRunner.toggle()
                if followRunner {
                    withAnimation {
                        cameraPosition = .region(MKCoordinateRegion(
                            center: viewModel.runnerCoordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
                        ))
                    }
                }
            } label: {
                Image(systemName: followRunner ? "location.fill" : "location")
                    .foregroundStyle(followRunner ? themeManager.selectedTheme.accentColor : .white)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .padding(.trailing, 12)
                    .padding(.top, 12)
            }
        }
    }

    // MARK: - POI icon builder

    @ViewBuilder
    private func poiIcon(for poi: PointOfInterest) -> some View {
        let (color, size): (Color, CGFloat) = {
            switch poi.category {
            case .toilet, .shower: return (.purple, 14)
            case .firstAid:       return (.red, 16)
            case .marshalPolice:  return (.orange, 13)
            case .marshal:        return (.yellow.opacity(0.7), 11)
            case .checkpoint:     return (.orange, 14)
            case .parking:        return (.gray, 13)
            case .music:          return (.pink, 14)
            case .turnDirection:  return (.white.opacity(0.5), 10)
            }
        }()

        Image(systemName: poi.sfSymbol)
            .font(.system(size: size))
            .foregroundStyle(color)
            .background(
                Circle()
                    .fill(.black.opacity(0.5))
                    .frame(width: size + 8, height: size + 8)
            )
    }
}
