import Foundation
import CoreLocation

final class RunTrackerViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {

    // MARK: - Published state

    @Published var elapsedTime: TimeInterval = 0
    @Published var distanceMeters: Double = 0
    @Published var paceMinPerKm: Double = 0
    @Published var elevationGainMeters: Double = 0
    @Published var runnerCoordinate: CLLocationCoordinate2D
    @Published var spectatorLocations: [SpectatorLocation]
    @Published var kmSplits: [KmSplit] = []
    @Published var voiceEnabled: Bool = true
    @Published var units: UnitSystem = .metric
    @Published var isTracking: Bool = false

    // GPX data
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    @Published var kmMarkers: [KmMarker] = []
    @Published var waterStations: [WaterStation] = []

    // MARK: - Private

    private let locationManager = CLLocationManager()
    private let voiceAlertManager = VoiceAlertManager()
    private var timer: Timer?
    private var startDate: Date?
    private var previousLocation: CLLocation?
    private var previousAltitude: Double?

    // MARK: - Units

    enum UnitSystem: String, CaseIterable, Identifiable {
        case metric
        case imperial
        var id: String { rawValue }
        var displayName: String { self == .metric ? "Metric (km)" : "Imperial (mi)" }
    }

    // MARK: - Init

    override init() {
        let start = CLLocationCoordinate2D(latitude: 36.0505, longitude: 14.2678)
        runnerCoordinate = start
        spectatorLocations = [
            SpectatorLocation(name: "Xagħra Square", coordinate: start),
            SpectatorLocation(name: "Ramla Bay Junction",
                              coordinate: CLLocationCoordinate2D(latitude: 36.0592, longitude: 14.2820)),
            SpectatorLocation(name: "Marsalforn Road",
                              coordinate: CLLocationCoordinate2D(latitude: 36.0738, longitude: 14.2581))
        ]
        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.activityType = .fitness
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.requestAlwaysAuthorization()

        loadGPX()
    }

    // MARK: - GPX

    private func loadGPX() {
        // Look for route.gpx in bundle or alongside the executable (for Package.swift builds)
        let candidates: [URL] = [
            Bundle.main.url(forResource: "route", withExtension: "gpx"),
            // Package.swift: file sits at repo root, two directories up from .build
            URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()  // GozoRun/
                .deletingLastPathComponent()  // Sources/
                .deletingLastPathComponent()  // repo root
                .appendingPathComponent("route.gpx")
        ].compactMap { $0 }

        for url in candidates {
            if FileManager.default.fileExists(atPath: url.path) {
                let result = GPXParser.parse(url: url)
                DispatchQueue.main.async {
                    self.routeCoordinates = result.trackPoints
                    self.kmMarkers = result.kmMarkers
                    self.waterStations = result.waterStations
                }
                return
            }
        }
    }

    // MARK: - Tracking

    func startTracking() {
        startDate = Date()
        previousLocation = nil
        previousAltitude = nil
        distanceMeters = 0
        elapsedTime = 0
        paceMinPerKm = 0
        elevationGainMeters = 0
        kmSplits.removeAll()
        voiceAlertManager.reset()
        isTracking = true

        locationManager.startUpdatingLocation()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let startDate = self.startDate else { return }
            self.elapsedTime = Date().timeIntervalSince(startDate)
            self.updatePace()
        }
    }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
        timer?.invalidate()
        timer = nil
        isTracking = false
    }

    // MARK: - Computed stats

    var elapsedFormatted: String {
        let h = Int(elapsedTime) / 3600
        let m = (Int(elapsedTime) % 3600) / 60
        let s = Int(elapsedTime) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    var paceFormatted: String {
        guard paceMinPerKm > 0 else { return "--:-- /km" }
        let totalSeconds = Int(paceMinPerKm * 60)
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%d:%02d /km", m, s)
    }

    var distanceFormatted: String {
        let km = distanceMeters / 1_000
        return String(format: "%.2f km", km)
    }

    var elevationFormatted: String {
        return String(format: "+%.0f m", elevationGainMeters)
    }

    // MARK: - Private helpers

    private func updatePace() {
        guard distanceMeters > 1 else { paceMinPerKm = 0; return }
        paceMinPerKm = (elapsedTime / 60) / (distanceMeters / 1_000)
    }

    private func recordSplitIfNeeded() {
        let completedKm = Int(distanceMeters / 1_000)
        if completedKm > kmSplits.count {
            for nextKm in (kmSplits.count + 1)...completedKm {
                kmSplits.append(KmSplit(kilometer: nextKm, elapsedTime: elapsedTime, paceMinPerKm: paceMinPerKm))
            }
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        runnerCoordinate = location.coordinate

        if let prev = previousLocation {
            distanceMeters += location.distance(from: prev)
        }
        previousLocation = location

        // Elevation gain
        if location.verticalAccuracy >= 0 {
            if let prevAlt = previousAltitude {
                let delta = location.altitude - prevAlt
                if delta > 0 { elevationGainMeters += delta }
            }
            previousAltitude = location.altitude
        }

        updatePace()
        recordSplitIfNeeded()

        // Voice alerts — proximity first, distance fallback
        if !kmMarkers.isEmpty {
            voiceAlertManager.checkProximity(to: location, kmMarkers: kmMarkers, elapsed: elapsedTime, enabled: voiceEnabled)
        } else {
            voiceAlertManager.announceSplitIfNeeded(distanceMeters: distanceMeters, elapsed: elapsedTime, enabled: voiceEnabled)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            break
        default:
            break
        }
    }
}
