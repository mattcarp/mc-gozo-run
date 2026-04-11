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
    @Published var cheerCount: Int = 0

    let liveTracking = LiveTrackingService(role: .runner)

    // GPX data
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    @Published var routeElevations: [Double] = []
    @Published var kmMarkers: [KmMarker] = []
    @Published var waterStations: [WaterStation] = []
    @Published var pointsOfInterest: [PointOfInterest] = []

    // MARK: - Private

    private let locationManager = CLLocationManager()
    let voiceAlertManager = VoiceAlertManager()
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
            SpectatorLocation(name: "Fiona", coordinate: start),
            SpectatorLocation(name: "Donal",
                              coordinate: CLLocationCoordinate2D(latitude: 36.0592, longitude: 14.2820)),
            SpectatorLocation(name: "Shelley",
                              coordinate: CLLocationCoordinate2D(latitude: 36.0738, longitude: 14.2581))
        ]
        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.activityType = .fitness
        locationManager.pausesLocationUpdatesAutomatically = false

        loadGPX()
    }

    // MARK: - GPX

    private func loadGPX() {
        let url = Bundle.main.url(forResource: "route", withExtension: "gpx")
            ?? bundleModuleURL()

        guard let gpxURL = url, FileManager.default.fileExists(atPath: gpxURL.path) else {
            return
        }
        let result = GPXParser.parse(url: gpxURL)
        DispatchQueue.main.async {
            self.routeCoordinates = result.trackPoints
            self.routeElevations = result.elevations
            self.kmMarkers = result.kmMarkers
            self.waterStations = result.waterStations
            self.pointsOfInterest = result.pointsOfInterest
        }
    }

    private func bundleModuleURL() -> URL? {
        #if SWIFT_PACKAGE
        return Bundle.module.url(forResource: "route", withExtension: "gpx")
        #else
        return nil
        #endif
    }

    // MARK: - Tracking

    func startTracking() {
        locationManager.requestAlwaysAuthorization()
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

        voiceAlertManager.announceRaceStart()

        liveTracking.connect()
        liveTracking.startPublishing(viewModel: self)

        if locationManager.authorizationStatus == .authorizedAlways ||
           locationManager.authorizationStatus == .authorizedWhenInUse {
            locationManager.allowsBackgroundLocationUpdates = true
        }
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
        liveTracking.disconnect()
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

        if location.verticalAccuracy >= 0 {
            if let prevAlt = previousAltitude {
                let delta = location.altitude - prevAlt
                if delta > 0 { elevationGainMeters += delta }
            }
            previousAltitude = location.altitude
        }

        updatePace()
        recordSplitIfNeeded()

        // Voice alerts: KM splits
        if !kmMarkers.isEmpty {
            voiceAlertManager.checkProximity(
                to: location,
                kmMarkers: kmMarkers,
                elapsed: elapsedTime,
                enabled: voiceEnabled
            )
        } else {
            voiceAlertManager.announceSplitIfNeeded(
                distanceMeters: distanceMeters,
                elapsed: elapsedTime,
                enabled: voiceEnabled
            )
        }

        // Voice alerts: water stations
        if !waterStations.isEmpty {
            voiceAlertManager.checkWaterStations(
                at: location,
                stations: waterStations,
                enabled: voiceEnabled
            )
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
