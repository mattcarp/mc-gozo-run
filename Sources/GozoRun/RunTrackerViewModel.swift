import Foundation
import CoreLocation

final class RunTrackerViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var elapsedTime: TimeInterval = 0
    @Published var distanceMeters: Double = 0
    @Published var paceMinPerKm: Double = 0
    @Published var runnerCoordinate: CLLocationCoordinate2D
    @Published var spectatorLocations: [SpectatorLocation]
    @Published var kmSplits: [KmSplit] = []

    @Published var voiceEnabled: Bool = true
    @Published var units: UnitSystem = .metric

    private let locationManager = CLLocationManager()
    private var timer: Timer?
    private var startDate: Date?
    private var previousLocation: CLLocation?

    enum UnitSystem: String, CaseIterable, Identifiable {
        case metric
        case imperial

        var id: String { rawValue }
        var displayName: String { self == .metric ? "Metric (km)" : "Imperial (mi)" }
    }

    override init() {
        let start = CLLocationCoordinate2D(latitude: 36.0505, longitude: 14.2678)
        runnerCoordinate = start
        spectatorLocations = [
            SpectatorLocation(name: "Xagħra Square", coordinate: start),
            SpectatorLocation(name: "Ramla Bay Junction", coordinate: CLLocationCoordinate2D(latitude: 36.0592, longitude: 14.2820)),
            SpectatorLocation(name: "Marsalforn Road", coordinate: CLLocationCoordinate2D(latitude: 36.0738, longitude: 14.2581))
        ]
        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .fitness
        locationManager.requestWhenInUseAuthorization()
    }

    func startTracking() {
        startDate = Date()
        previousLocation = nil
        distanceMeters = 0
        elapsedTime = 0
        paceMinPerKm = 0
        kmSplits.removeAll()

        locationManager.startUpdatingLocation()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let startDate else { return }
            elapsedTime = Date().timeIntervalSince(startDate)
            updatePace()
            updateSplitsIfNeeded()
        }
    }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
        timer?.invalidate()
        timer = nil
    }

    private func updatePace() {
        guard distanceMeters > 1 else {
            paceMinPerKm = 0
            return
        }
        let km = distanceMeters / 1_000
        paceMinPerKm = (elapsedTime / 60) / km
    }

    private func updateSplitsIfNeeded() {
        let completedKm = Int(distanceMeters / 1_000)
        if completedKm > kmSplits.count {
            for nextKm in (kmSplits.count + 1)...completedKm {
                kmSplits.append(
                    KmSplit(
                        kilometer: nextKm,
                        elapsedTime: elapsedTime,
                        paceMinPerKm: paceMinPerKm
                    )
                )
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        runnerCoordinate = location.coordinate
        if let previousLocation {
            distanceMeters += location.distance(from: previousLocation)
        }
        previousLocation = location
        updatePace()
        updateSplitsIfNeeded()
    }
}
