import Foundation
import AVFoundation
import CoreLocation

final class VoiceAlertManager: NSObject, AVSpeechSynthesizerDelegate {

    private let synthesizer = AVSpeechSynthesizer()
    private var announcedKilometers: Set<Int> = []
    private var announcedWaterStations: Set<UUID> = []
    private var announcedMilestones: Set<String> = []
    private var selectedVoice: AVSpeechSynthesisVoice?
    private var isSessionConfigured = false

    private let proximityRadiusMeters: Double = 80
    private let waterStationAlertRadius: Double = 250

    override init() {
        super.init()
        synthesizer.delegate = self
        selectBestVoice()
    }

    func reset() {
        announcedKilometers.removeAll()
        announcedWaterStations.removeAll()
        announcedMilestones.removeAll()
        synthesizer.stopSpeaking(at: .immediate)
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        guard !isSessionConfigured else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playback,
                mode: .voicePrompt,
                options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers]
            )
            try session.setActive(true)
            isSessionConfigured = true
        } catch {
            // Speech still works with default session
        }
    }

    // MARK: - Voice Selection

    private func selectBestVoice() {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        let englishVoices = allVoices.filter { $0.language.starts(with: "en") }

        #if DEBUG
        for v in englishVoices {
            print("[Voice] \(v.language) | \(v.name) | \(v.quality.rawValue) | \(v.identifier)")
        }
        #endif

        // Prefer enhanced/premium voices in order of naturalness
        let preferredIdentifiers = [
            "com.apple.voice.premium.en-GB.Malcolm",
            "com.apple.voice.premium.en-GB.Daniel",
            "com.apple.voice.premium.en-AU.Karen",
            "com.apple.voice.premium.en-US.Zoe",
            "com.apple.voice.enhanced.en-GB.Malcolm",
            "com.apple.voice.enhanced.en-GB.Daniel",
            "com.apple.voice.enhanced.en-AU.Karen",
            "com.apple.voice.enhanced.en-US.Samantha",
            "com.apple.voice.enhanced.en-US.Joelle",
            "com.apple.voice.enhanced.en-US.Noelle",
        ]

        for identifier in preferredIdentifiers {
            if let voice = AVSpeechSynthesisVoice(identifier: identifier) {
                print("[Voice] Selected: \(voice.name) (\(voice.identifier))")
                selectedVoice = voice
                return
            }
        }

        // Fallback: any enhanced English voice
        if let enhanced = englishVoices.first(where: { $0.quality == .enhanced }) {
            print("[Voice] Fallback enhanced: \(enhanced.name)")
            selectedVoice = enhanced
            return
        }

        // Fallback: best available Siri voice (British)
        let siriGB = englishVoices.first { $0.identifier.contains("siri") && $0.language == "en-GB" }
        if let siri = siriGB {
            print("[Voice] Fallback Siri GB: \(siri.name)")
            selectedVoice = siri
            return
        }

        // Final fallback
        selectedVoice = AVSpeechSynthesisVoice(language: "en-GB")
        print("[Voice] Using default en-GB voice")
    }

    // MARK: - Proximity-based KM detection

    func checkProximity(
        to location: CLLocation,
        kmMarkers: [KmMarker],
        elapsed: TimeInterval,
        enabled: Bool
    ) {
        guard enabled else { return }
        for marker in kmMarkers {
            guard !announcedKilometers.contains(marker.kilometer) else { continue }
            let markerLocation = CLLocation(
                latitude: marker.coordinate.latitude,
                longitude: marker.coordinate.longitude
            )
            if location.distance(from: markerLocation) <= proximityRadiusMeters {
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

    // MARK: - Water Station Alerts

    func checkWaterStations(at location: CLLocation, stations: [WaterStation], enabled: Bool) {
        guard enabled else { return }
        for station in stations {
            guard !announcedWaterStations.contains(station.id) else { continue }
            let stationLoc = CLLocation(
                latitude: station.coordinate.latitude,
                longitude: station.coordinate.longitude
            )
            if location.distance(from: stationLoc) <= waterStationAlertRadius {
                announcedWaterStations.insert(station.id)
                announceWaterStation()
                break
            }
        }
    }

    // MARK: - Cheer Announcement

    func announceCheer(from name: String? = nil) {
        let phrases: [String]
        if let name = name, !name.isEmpty {
            phrases = [
                "\(name) is cheering for you! Keep it up!",
                "A cheer from \(name)! They're watching you run!",
                "\(name) says you're doing amazing!",
            ]
        } else {
            phrases = [
                "You've got a cheer! Someone's rooting for you!",
                "Cheer received! They believe in you!",
                "Your fans are watching! Keep pushing!",
            ]
        }
        speak(pickRandom(phrases), priority: false)
    }

    // MARK: - Race Start

    func announceRaceStart() {
        speak("Let's go! The Gozo Half Marathon starts now. Enjoy every kilometre of this beautiful island.", priority: true)
    }

    // MARK: - Race Completion

    func announceRaceComplete(elapsed: TimeInterval) {
        let timeStr = formatTimeNatural(elapsed)
        speak(
            "You did it! Twenty-one point one kilometres through beautiful Gozo! " +
            "You finished in \(timeStr). What an incredible achievement. " +
            "Congratulations, Mattie!",
            priority: true
        )
    }

    // MARK: - Public speak (for DemoMode and external callers)

    func say(_ text: String) {
        speak(text, priority: true)
    }

    // MARK: - KM Announcements

    private func announceKilometer(_ km: Int, elapsed: TimeInterval) {
        configureAudioSession()

        let paceStr = formatPaceNatural(elapsed: elapsed, kilometer: km)
        let text: String

        switch km {
        case 1:
            text = pickRandom([
                "First K done, \(paceStr). Find your rhythm and settle in.",
                "One K in the bag, running \(paceStr). Nice and easy.",
                "One down! \(paceStr). Long road ahead, enjoy the scenery.",
            ])

        case 5:
            announcedMilestones.insert("5K")
            text = pickRandom([
                "Five K! Quarter of the way. You're running \(paceStr). Feeling strong!",
                "Five down, sixteen to go. \(paceStr). Beautiful morning for it.",
                "Five K mark! \(paceStr). You're right on target.",
            ])

        case 10:
            announcedMilestones.insert("10K")
            text = pickRandom([
                "Ten K! Nearly halfway. \(paceStr). You're doing brilliantly.",
                "Double digits! Ten K at \(paceStr). You own this course.",
            ])

        case 11:
            announcedMilestones.insert("halfway")
            text = pickRandom([
                "Halfway! Ten point five K done. \(paceStr). The second half is yours.",
                "You're past halfway now! Running \(paceStr). This is where it counts.",
            ])

        case 15:
            announcedMilestones.insert("15K")
            text = pickRandom([
                "Fifteen K! Only six to go. \(paceStr). Dig deep, you've absolutely got this.",
                "Fifteen down! \(paceStr). Think of that finish line in Xaghra Square.",
            ])

        case 18:
            text = pickRandom([
                "Eighteen K! Three more. \(paceStr). You can taste the finish!",
                "Just three K left! Almost there, \(paceStr). Keep pushing!",
            ])

        case 19:
            text = pickRandom([
                "Nineteen! Two K to go. Give it everything you've got!",
                "Two to go! The crowd is waiting for you!",
            ])

        case 20:
            text = pickRandom([
                "Twenty K! One more kilometre! Sprint it home, Mattie!",
                "Twenty! You're almost there! Final push now!",
            ])

        case 21:
            text = "Twenty-one K! The finish line is right there! Go go go!"

        default:
            text = pickRandom(regularKmPhrases(km: km, pace: paceStr))
        }

        speak(text)
    }

    private func announceWaterStation() {
        let phrases = [
            "Water station coming up. Grab a cup, stay hydrated.",
            "Water ahead! Take a sip and keep your rhythm.",
            "Hydration point just ahead. Drink up!",
        ]
        speak(pickRandom(phrases), priority: false)
    }

    private func regularKmPhrases(km: Int, pace: String) -> [String] {
        let remaining = 21 - km
        var phrases = [
            "\(km) K done, running \(pace). \(remaining) to go.",
            "K \(km) in the books. \(pace). Keep it steady.",
            "\(km) K! \(pace). You're looking strong.",
            "\(km) K ticked off at \(pace). Solid running.",
        ]

        if km >= 12 && km <= 16 {
            phrases.append("\(km) K. \(pace). The hard middle. Stay mentally tough.")
        }
        if remaining <= 5 {
            phrases.append("\(km) K! Only \(remaining) left! \(pace). You're so close!")
        }

        return phrases
    }

    // MARK: - Core Speech

    private func speak(_ text: String, priority: Bool = true) {
        configureAudioSession()

        if priority {
            synthesizer.stopSpeaking(at: .word)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.47
        utterance.pitchMultiplier = 1.05
        utterance.volume = 1.0
        utterance.preUtteranceDelay = 0.2
        utterance.postUtteranceDelay = 0.4

        if let voice = selectedVoice {
            utterance.voice = voice
        }

        synthesizer.speak(utterance)
    }

    // MARK: - Natural Formatting

    private func formatPaceNatural(elapsed: TimeInterval, kilometer: Int) -> String {
        guard kilometer > 0 else { return "unknown pace" }
        let secondsPerKm = elapsed / Double(kilometer)
        let minutes = Int(secondsPerKm / 60)
        let seconds = Int(secondsPerKm.truncatingRemainder(dividingBy: 60))

        if seconds == 0 {
            return "\(minutes) flat per K"
        }
        let secStr = seconds < 10 ? "oh \(seconds)" : "\(seconds)"
        return "\(minutes) \(secStr) per K"
    }

    private func formatTimeNatural(_ elapsed: TimeInterval) -> String {
        let h = Int(elapsed) / 3600
        let m = (Int(elapsed) % 3600) / 60
        let s = Int(elapsed) % 60

        if h > 0 {
            if m == 0 { return "\(h) hours exactly" }
            if s == 0 { return "\(h) hours and \(m) minutes" }
            return "\(h) hours, \(m) minutes, and \(s) seconds"
        }
        if s == 0 { return "\(m) minutes" }
        return "\(m) minutes and \(s) seconds"
    }

    private func pickRandom(_ options: [String]) -> String {
        options.randomElement() ?? options[0]
    }

    // MARK: - AVSpeechSynthesizerDelegate

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
