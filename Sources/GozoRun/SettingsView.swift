import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: RunTrackerViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Theme") {
                    Picker("App Theme", selection: $themeManager.selectedTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Run Preferences") {
                    Picker("Units", selection: $viewModel.units) {
                        ForEach(RunTrackerViewModel.UnitSystem.allCases) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }

                    Toggle("Voice Alerts", isOn: $viewModel.voiceEnabled)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
