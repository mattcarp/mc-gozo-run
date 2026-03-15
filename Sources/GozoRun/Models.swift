import Foundation
import CoreLocation

struct RunSession: Identifiable {
    let id = UUID()
    let raceName: String
    let startDate: Date
    let startCoordinate: CLLocationCoordinate2D
    let totalDistanceKm: Double
}

struct SpectatorLocation: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
}

struct KmSplit: Identifiable {
    let id = UUID()
    let kilometer: Int
    let elapsedTime: TimeInterval
    let paceMinPerKm: Double
}
