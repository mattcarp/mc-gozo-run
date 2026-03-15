import SwiftUI

struct ContentView: View {
    @ObservedObject var runTracker: RunTrackerViewModel
    let raceSession: RunSession

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Il-Girja t'Ghawdex")
                .font(.headline)
            Text("Gozo Half Marathon • 21.1 km")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(countdownText)
                .font(.callout)
                .foregroundStyle(.orange)
            statsRow
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var statsRow: some View {
        HStack {
            Text(String(format: "Distance: %.2f km", runTracker.distanceMeters / 1_000))
            Spacer()
            Text(String(format: "Pace: %.2f min/km", runTracker.paceMinPerKm))
        }
        .font(.caption)
    }

    private var countdownText: String {
        let now = Date()
        if now >= raceSession.startDate {
            return "Race day is live"
        }

        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: now, to: raceSession.startDate)
        let d = components.day ?? 0
        let h = components.hour ?? 0
        let m = components.minute ?? 0
        return "Countdown: \(d)d \(h)h \(m)m"
    }
}
