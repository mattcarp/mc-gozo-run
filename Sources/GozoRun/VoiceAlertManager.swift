import Foundation
import AVFoundation

final class VoiceAlertManager {
    private let synthesizer = AVSpeechSynthesizer()
    private var announcedKilometers: Set<Int> = []

    func reset() {
        announcedKilometers.removeAll()
    }

    func announceSplitIfNeeded(distanceMeters: Double, elapsed: TimeInterval, enabled: Bool) {
        guard enabled else { return }
        let kilometer = Int(distanceMeters / 1_000)
        guard kilometer > 0, !announcedKilometers.contains(kilometer) else { return }

        announcedKilometers.insert(kilometer)
        let paceMinPerKm = (elapsed / 60) / Double(kilometer)
        let utterance = AVSpeechUtterance(
            string: "Kilometer \(kilometer). Average pace \(String(format: "%.2f", paceMinPerKm)) minutes per kilometer."
        )
        utterance.rate = 0.5
        synthesizer.speak(utterance)
    }
}
