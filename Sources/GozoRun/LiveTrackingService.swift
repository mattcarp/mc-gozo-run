import Foundation
import CoreLocation

/// Lightweight Supabase Realtime client for sharing runner GPS and receiving cheers.
/// Zero external dependencies — uses URLSession + native WebSocket.
final class LiveTrackingService: ObservableObject {

    // MARK: - Configuration

    struct Config {
        let supabaseURL: String
        let supabaseAnonKey: String
        let raceCode: String

        static let shared: Config = {
            // These will be set via environment or a plist in release builds.
            // For development, hardcode or read from UserDefaults.
            let url = UserDefaults.standard.string(forKey: "supabase_url") ?? ""
            let key = UserDefaults.standard.string(forKey: "supabase_key") ?? ""
            let code = UserDefaults.standard.string(forKey: "race_code") ?? "GOZO2026"
            return Config(supabaseURL: url, supabaseAnonKey: key, raceCode: code)
        }()
    }

    enum Role { case runner, spectator }

    // MARK: - Published state

    @Published var isConnected = false
    @Published var runnerPosition: CLLocationCoordinate2D?
    @Published var runnerDistanceKm: Double = 0
    @Published var runnerPace: String = "--:--"
    @Published var cheerCount: Int = 0
    @Published var lastCheerAt: Date?

    // MARK: - Private

    private let config: Config
    private let role: Role
    private var wsTask: URLSessionWebSocketTask?
    private var publishTimer: Timer?

    init(config: Config = .shared, role: Role) {
        self.config = config
        self.role = role
    }

    // MARK: - REST API (publish position / send cheer)

    /// Runner publishes position via REST INSERT (called every 5s)
    func publishPosition(coordinate: CLLocationCoordinate2D, distanceKm: Double, pace: String, elapsed: TimeInterval) {
        guard !config.supabaseURL.isEmpty else { return }

        let url = URL(string: "\(config.supabaseURL)/rest/v1/gozo_live_positions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(config.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

        let body: [String: Any] = [
            "race_code": config.raceCode,
            "runner_name": "Mattie",
            "lat": coordinate.latitude,
            "lon": coordinate.longitude,
            "distance_km": distanceKm,
            "pace": pace,
            "elapsed_seconds": Int(elapsed)
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request).resume()
    }

    /// Spectator sends a cheer via REST INSERT
    func sendCheer(from spectatorName: String) {
        guard !config.supabaseURL.isEmpty else { return }

        let url = URL(string: "\(config.supabaseURL)/rest/v1/gozo_cheers")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(config.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

        let body: [String: Any] = [
            "race_code": config.raceCode,
            "spectator_name": spectatorName
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request).resume()
    }

    // MARK: - Realtime WebSocket (subscribe to position updates / cheers)

    func connect() {
        guard !config.supabaseURL.isEmpty, !config.supabaseAnonKey.isEmpty else { return }

        let realtimeURL = config.supabaseURL
            .replacingOccurrences(of: "https://", with: "wss://")
            .replacingOccurrences(of: "http://", with: "ws://")
        let wsURL = URL(string: "\(realtimeURL)/realtime/v1/websocket?apikey=\(config.supabaseAnonKey)&vsn=1.0.0")!

        let session = URLSession(configuration: .default)
        wsTask = session.webSocketTask(with: wsURL)
        wsTask?.resume()

        // Join the appropriate channel
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.joinChannel()
        }

        receiveMessages()
        isConnected = true
    }

    func disconnect() {
        wsTask?.cancel(with: .goingAway, reason: nil)
        publishTimer?.invalidate()
        isConnected = false
    }

    private func joinChannel() {
        let table = role == .runner ? "gozo_cheers" : "gozo_live_positions"
        let joinMsg: [String: Any] = [
            "topic": "realtime:public:\(table)",
            "event": "phx_join",
            "payload": ["config": ["broadcast": ["self": false], "postgres_changes": [
                ["event": "INSERT", "schema": "public", "table": table,
                 "filter": "race_code=eq.\(config.raceCode)"]
            ]]],
            "ref": "1"
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: joinMsg),
              let text = String(data: data, encoding: .utf8) else { return }

        wsTask?.send(.string(text)) { _ in }

        // Heartbeat every 30s
        startHeartbeat()
    }

    private func receiveMessages() {
        wsTask?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(.string(let text)):
                self.handleMessage(text)
            default:
                break
            }
            self.receiveMessages()
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let event = json["event"] as? String,
              event == "postgres_changes",
              let payload = json["payload"] as? [String: Any],
              let record = payload["record"] as? [String: Any] else { return }

        DispatchQueue.main.async {
            if self.role == .spectator {
                // Received runner position update
                if let lat = record["lat"] as? Double,
                   let lon = record["lon"] as? Double {
                    self.runnerPosition = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    self.runnerDistanceKm = (record["distance_km"] as? Double) ?? 0
                    self.runnerPace = (record["pace"] as? String) ?? "--:--"
                }
            } else {
                // Runner received a cheer
                self.cheerCount += 1
                self.lastCheerAt = Date()
            }
        }
    }

    private func startHeartbeat() {
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            let hb: [String: Any] = [
                "topic": "phoenix",
                "event": "heartbeat",
                "payload": [:],
                "ref": "hb"
            ]
            guard let data = try? JSONSerialization.data(withJSONObject: hb),
                  let text = String(data: data, encoding: .utf8) else { return }
            self?.wsTask?.send(.string(text)) { _ in }
        }
    }

    // MARK: - Runner auto-publish

    func startPublishing(viewModel: RunTrackerViewModel) {
        publishTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self, weak viewModel] _ in
            guard let vm = viewModel else { return }
            self?.publishPosition(
                coordinate: vm.runnerCoordinate,
                distanceKm: vm.distanceMeters / 1000,
                pace: vm.paceFormatted,
                elapsed: vm.elapsedTime
            )
        }
    }
}
