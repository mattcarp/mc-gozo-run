import Foundation
import AVFoundation
import CoreLocation

final class VoiceAlertManager {
    private let synthesizer = AVSpeechSynthesizer()
    private var announcedKilometers: Set<Int> = []

    private let proximityRadiusMeters: Double = 80

    func reset() {
        announcedKilometers.removeAll()
    }

    // MARK: - Proximity-based detection (primary)

    func checkProximity(to location: CLLocation, kmMarkers: [KmMarker], elapsed: TimeInterval, enabled: Bool) {
        guard enabled else { return }
        for marker in kmMarkers {
            guard !announcedKilometers.contains(marker.kilometer) else { continue }
            let markerLocation = CLLocation(latitude: marker.coordinate.latitude, longitude: marker.coordinate.longitude)
            let distance = location.distance(from: markerLocation)
            if distance <= proximityRadiusMeters {
                announcedKilometers.insert(marker.kilometer)
                announceKilometer(marker.kilometer, elapsed: elapsed)
                break
            }
        }
    }

    // MARK: - Distance-based fallback

    func announceSplitIfNeeded(distanceMeters: Double, elapsed: TimeInterval, enabled: Bool) {
        guard enabled else { return }
        let kilometer = Int(distanceMeters / 1_000)
        guard kilometer > 0, !announcedKilometers.contains(kilometer) else { return }
        announcedKilometers.insert(kilometer)
        announceKilometer(kilometer, elapsed: elapsed)
    }

    // MARK: - Speech

    private func announceKilometer(_ km: Int, elapsed: TimeInterval) {
        let paceString = formatPace(elapsed: elapsed, kilometer: km)
        let text = "Kilometre \(km). Pace: \(paceString) per kilometre."
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.48
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        synthesizer.speak(utterance)
    }

    private func formatPace(elapsed: TimeInterval, kilometer: Int) -> String {
        guard kilometer > 0 else { return "unknown" }
        let secondsPerKm = elapsed / Double(kilometer)
        let minutes = Int(secondsPerKm / 60)
        let seconds = Int(secondsPerKm.truncatingRemainder(dividingBy: 60))
        if seconds == 0 {
            return "\(minutes) minutes"
        }
        return "\(minutes) minutes, \(seconds) seconds"
    }
}
