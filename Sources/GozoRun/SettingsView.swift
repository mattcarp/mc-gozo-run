import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: RunTrackerViewModel

    @State private var showDemoMode = false
    @State private var precacheProgress: (Int, Int)?
    @State private var isPrecaching = false

    @AppStorage("supabase_url") private var supabaseURL = "https://cnmzahjpvxtnsvhnguqe.supabase.co"
    @AppStorage("supabase_key") private var supabaseKey = "sb_publishable_IIYa7pcz7LXsIdke9RxQiw_DIzMA1-4"
    @AppStorage("race_code") private var raceCode = "GOZO2026"
    @AppStorage("google_streetview_key") private var streetViewKey = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(AppTheme.allCases) { theme in
                        ThemeRow(theme: theme, isSelected: themeManager.selectedTheme == theme) {
                            withAnimation(.spring(response: 0.3)) {
                                themeManager.selectedTheme = theme
                            }
                        }
                    }
                } header: {
                    Text("App Theme")
                } footer: {
                    Text("Theme applies live — no restart needed.")
                }

                Section("Run Preferences") {
                    Picker("Units", selection: $viewModel.units) {
                        ForEach(RunTrackerViewModel.UnitSystem.allCases) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }

                    Toggle("Voice KM Alerts", isOn: $viewModel.voiceEnabled)
                        .tint(themeManager.selectedTheme.accentColor)
                }

                Section("Race Info") {
                    LabeledContent("Race", value: "Gozo Half Marathon")
                    LabeledContent("Distance", value: "21.1 km")
                    LabeledContent("Date", value: "26 April 2026")
                    LabeledContent("Start", value: "07:30 Malta Time")
                    LabeledContent("Location", value: "Xaghra Square, Gozo")
                }

                Section("Route") {
                    LabeledContent("Track points", value: "\(viewModel.routeCoordinates.count)")
                    LabeledContent("KM markers", value: "\(viewModel.kmMarkers.count)")
                    LabeledContent("Water stations", value: "\(viewModel.waterStations.count)")
                    LabeledContent("Points of interest", value: "\(viewModel.pointsOfInterest.count)")
                    LabeledContent("Elevation range", value: "6m – 144m")
                }

                Section {
                    SecureField("Google Street View API Key", text: $streetViewKey)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    Button {
                        Task { await precacheStreetView() }
                    } label: {
                        HStack {
                            Label(
                                isPrecaching ? "Downloading..." : "Pre-cache Route Imagery",
                                systemImage: isPrecaching ? "arrow.down.circle" : "photo.on.rectangle.angled"
                            )
                            .font(.headline)
                            .foregroundStyle(streetViewKey.isEmpty ? .secondary : themeManager.selectedTheme.accentColor)

                            Spacer()

                            if let (done, total) = precacheProgress {
                                Text("\(done)/\(total)")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .disabled(streetViewKey.isEmpty || isPrecaching || viewModel.routeCoordinates.isEmpty)

                    if isPrecaching, let (done, total) = precacheProgress {
                        ProgressView(value: Double(done), total: Double(total))
                            .tint(themeManager.selectedTheme.accentColor)
                    }
                } header: {
                    Text("Street View (Look Ahead)")
                } footer: {
                    if streetViewKey.isEmpty {
                        Text("Add your Google Maps API key to enable street-level previews. Pre-cache the night before the race for offline use.")
                    } else if let (done, total) = precacheProgress, done == total {
                        Label("\(total) images cached — ready for race day", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Text("Pre-caching downloads ~100 street view images (about 15MB). Run this on Wi-Fi the night before.")
                    }
                }

                Section {
                    Button {
                        showDemoMode = true
                    } label: {
                        Label("Launch Demo Mode", systemImage: "play.display")
                            .font(.headline)
                            .foregroundStyle(themeManager.selectedTheme.accentColor)
                    }
                } header: {
                    Text("Demo")
                } footer: {
                    Text("Runs the full race route automatically with voice alerts and street-level previews. Perfect for showing on a TV.")
                }

                Section {
                    TextField("Supabase URL", text: $supabaseURL)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    SecureField("Supabase Anon Key", text: $supabaseKey)
                    TextField("Race Code", text: $raceCode)
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                } header: {
                    Text("Live Tracking")
                } footer: {
                    if supabaseURL.isEmpty {
                        Text("Enter your Supabase project URL to enable live spectator tracking.")
                    } else {
                        Label("Live tracking configured", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                Section {
                    LabeledContent("Cheers received", value: "\(viewModel.liveTracking.cheerCount)")
                    LabeledContent("Connection", value: viewModel.liveTracking.isConnected ? "Connected" : "Disconnected")
                } header: {
                    Text("Live Status")
                }
            }
            .navigationTitle("Settings")
            .fullScreenCover(isPresented: $showDemoMode) {
                DemoModeView(viewModel: viewModel)
                    .environmentObject(themeManager)
            }
        }
    }

    private func precacheStreetView() async {
        isPrecaching = true
        Analytics.shared.track("precache_started", properties: ["route_points": viewModel.routeCoordinates.count])

        await StreetViewCache.shared.precacheRoute(
            coordinates: viewModel.routeCoordinates,
            intervalMeters: 200
        ) { done, total in
            DispatchQueue.main.async {
                self.precacheProgress = (done, total)
            }
        }

        isPrecaching = false
        Analytics.shared.track("precache_complete", properties: ["images": precacheProgress?.1 ?? 0])
    }
}

// MARK: - Theme Row

private struct ThemeRow: View {
    let theme: AppTheme
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.backgroundColor)
                    .frame(width: 44, height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(theme.accentColor)
                            .frame(width: 16, height: 16)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? theme.accentColor : Color.clear, lineWidth: 2)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.displayName)
                        .font(.body)
                        .foregroundStyle(.primary)
                    Text(themeSubtitle(theme))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(theme.accentColor)
                        .font(.title3)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func themeSubtitle(_ t: AppTheme) -> String {
        switch t {
        case .limestone:     return "Warm limestone · Teal accent"
        case .mediterranean:  return "Cool sea · Blue accent"
        case .sunset:   return "Golden glow · Coral accent"
        case .terracotta: return "Bold earth · Mint accent"
        }
    }
}
