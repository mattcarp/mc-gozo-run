import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: RunTrackerViewModel

    var body: some View {
        NavigationStack {
            Form {
                // Theme picker with previews
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
                    LabeledContent("Location", value: "Xagħra Square, Gozo")
                }

                Section("Route") {
                    LabeledContent("Track points", value: "\(viewModel.routeCoordinates.count)")
                    LabeledContent("KM markers", value: "\(viewModel.kmMarkers.count)")
                    LabeledContent("Water stations", value: "\(viewModel.waterStations.count)")
                    LabeledContent("Points of interest", value: "\(viewModel.pointsOfInterest.count)")
                    LabeledContent("Elevation range", value: "6m – 144m")
                }
            }
            .navigationTitle("Settings")
        }
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
                // Colour swatch
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
        case .darkCyan:     return "Dark background · Cyan accent"
        case .darkDefault:  return "Dark background · White accent"
        case .lightCoral:   return "Light background · Coral accent"
        case .spectatorDark: return "Dark background · Orange accent"
        }
    }
}
