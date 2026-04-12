import Foundation
import CoreLocation
import os.log
import UIKit

final class Analytics: @unchecked Sendable {
    static let shared = Analytics()

    private let logger = Logger(subsystem: "com.mattcarp.GozoRun", category: "Analytics")
    private let supabaseURL: String
    private let supabaseKey: String
    private let raceCode: String
    private let sessionId: String
    private let deviceModel: String
    private var eventBuffer: [[String: Any]] = []
    private let bufferQueue = DispatchQueue(label: "com.mattcarp.GozoRun.analytics")
    private let flushInterval: TimeInterval = 30
    private var flushTimer: Timer?

    private init() {
        let config = LiveTrackingService.Config.shared
        self.supabaseURL = config.supabaseURL
        self.supabaseKey = config.supabaseAnonKey
        self.raceCode = config.raceCode
        self.sessionId = UUID().uuidString
        self.deviceModel = UIDevice.current.model

        startPeriodicFlush()
        trackAppLifecycle()

        logger.info("[Analytics] Session started: \(self.sessionId, privacy: .public)")
    }

    // MARK: - Public API

    func track(_ event: String, properties: [String: Any] = [:]) {
        var payload = properties
        payload["event"] = event
        payload["session_id"] = sessionId
        payload["race_code"] = raceCode
        payload["device_model"] = deviceModel
        payload["timestamp"] = ISO8601DateFormatter().string(from: Date())
        payload["battery_level"] = Int(UIDevice.current.batteryLevel * 100)
        payload["battery_state"] = batteryStateString()

        logger.info("[Event] \(event, privacy: .public): \(String(describing: properties), privacy: .public)")

        bufferQueue.async {
            self.eventBuffer.append(payload)
            if self.eventBuffer.count >= 10 {
                self.flush()
            }
        }
    }

    // MARK: - GPS Tracking Events

    func trackGPSUpdate(coordinate: CLLocationCoordinate2D, accuracy: CLLocationAccuracy, altitude: Double) {
        track("gps_update", properties: [
            "lat": coordinate.latitude,
            "lon": coordinate.longitude,
            "accuracy_m": accuracy,
            "altitude": altitude
        ])
    }

    func trackGPSError(_ error: Error) {
        track("gps_error", properties: [
            "error": error.localizedDescription
        ])
    }

    // MARK: - Voice Events

    func trackVoiceAlert(type: String, km: Int, message: String) {
        track("voice_alert", properties: [
            "type": type,
            "km": km,
            "message": message
        ])
    }

    func trackVoiceError(_ error: String) {
        track("voice_error", properties: ["error": error])
    }

    func trackVoiceSelection(voiceId: String, quality: String) {
        track("voice_selected", properties: [
            "voice_id": voiceId,
            "quality": quality
        ])
    }

    // MARK: - Live Tracking Events

    func trackPublishSuccess(distanceKm: Double, latency: TimeInterval) {
        track("publish_success", properties: [
            "distance_km": distanceKm,
            "latency_ms": Int(latency * 1000)
        ])
    }

    func trackPublishFailure(error: String) {
        track("publish_failure", properties: ["error": error])
    }

    // MARK: - Look Around Events

    func trackLookAroundLoad(coordinate: CLLocationCoordinate2D, durationMs: Int, success: Bool) {
        track("look_around", properties: [
            "lat": coordinate.latitude,
            "lon": coordinate.longitude,
            "duration_ms": durationMs,
            "success": success
        ])
    }

    // MARK: - Race Events

    func trackRaceStart(mode: String) {
        UIDevice.current.isBatteryMonitoringEnabled = true
        track("race_start", properties: [
            "mode": mode,
            "battery_level": Int(UIDevice.current.batteryLevel * 100)
        ])
    }

    func trackRaceComplete(distanceKm: Double, elapsed: TimeInterval, avgPace: String) {
        track("race_complete", properties: [
            "distance_km": distanceKm,
            "elapsed_seconds": Int(elapsed),
            "avg_pace": avgPace,
            "battery_level": Int(UIDevice.current.batteryLevel * 100)
        ])
    }

    func trackKmSplit(km: Int, elapsed: TimeInterval, pace: String, gpsAccuracy: Double) {
        track("km_split", properties: [
            "km": km,
            "elapsed_seconds": Int(elapsed),
            "pace": pace,
            "gps_accuracy_m": gpsAccuracy
        ])
    }

    // MARK: - Social Events

    func trackCheerSent(from spectator: String) {
        track("cheer_sent", properties: ["spectator": spectator])
    }

    func trackCheerReceived(count: Int) {
        track("cheer_received", properties: ["total_count": count])
    }

    // MARK: - App Lifecycle

    private func trackAppLifecycle() {
        UIDevice.current.isBatteryMonitoringEnabled = true

        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.track("app_backgrounded")
            self?.flush()
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.track("app_foregrounded")
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.track("app_terminated")
            self?.flush()
        }

        NotificationCenter.default.addObserver(
            forName: UIDevice.batteryLevelDidChangeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            let level = Int(UIDevice.current.batteryLevel * 100)
            if level % 10 == 0 {
                self?.track("battery_milestone", properties: ["level": level])
            }
        }
    }

    // MARK: - Flush to Supabase

    private func startPeriodicFlush() {
        DispatchQueue.main.async {
            self.flushTimer = Timer.scheduledTimer(withTimeInterval: self.flushInterval, repeats: true) { [weak self] _ in
                self?.bufferQueue.async { self?.flush() }
            }
        }
    }

    private func flush() {
        guard !eventBuffer.isEmpty, !supabaseURL.isEmpty else { return }

        let events = eventBuffer
        eventBuffer.removeAll()

        let rows = events.map { event -> [String: Any] in
            return [
                "session_id": event["session_id"] ?? "",
                "race_code": event["race_code"] ?? "",
                "event_name": event["event"] ?? "",
                "device_model": event["device_model"] ?? "",
                "battery_level": event["battery_level"] ?? -1,
                "properties": jsonString(from: event),
                "created_at": event["timestamp"] ?? ""
            ]
        }

        guard let url = URL(string: "\(supabaseURL)/rest/v1/gozo_analytics") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = try? JSONSerialization.data(withJSONObject: rows)

        URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
            if let error {
                self?.logger.error("[Analytics] Flush failed: \(error.localizedDescription, privacy: .public)")
            } else if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
                self?.logger.warning("[Analytics] Flush HTTP \(http.statusCode)")
            } else {
                self?.logger.info("[Analytics] Flushed \(events.count) events")
            }
        }.resume()
    }

    // MARK: - Helpers

    private func jsonString(from dict: [String: Any]) -> String {
        let clean = dict.filter { $0.key != "session_id" && $0.key != "race_code" && $0.key != "device_model" && $0.key != "timestamp" }
        guard let data = try? JSONSerialization.data(withJSONObject: clean),
              let str = String(data: data, encoding: .utf8) else { return "{}" }
        return str
    }

    private func batteryStateString() -> String {
        switch UIDevice.current.batteryState {
        case .unplugged: return "unplugged"
        case .charging: return "charging"
        case .full: return "full"
        case .unknown: return "unknown"
        @unknown default: return "unknown"
        }
    }
}
