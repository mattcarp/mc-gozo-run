import SwiftUI

/// Entry screen for spectators to join a race by code.
/// Shown when spectator mode is opened and no race code is configured.
struct JoinRaceView: View {
    @AppStorage("race_code") private var raceCode = "GOZO2026"
    @AppStorage("spectator_name") private var spectatorName = "Fiona"
    @EnvironmentObject var themeManager: ThemeManager

    @State private var inputCode = ""
    @State private var inputName = ""
    let onJoin: (String, String) -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Header
            VStack(spacing: 12) {
                Image(systemName: "figure.run.circle")
                    .font(.system(size: 56))
                    .foregroundStyle(themeManager.selectedTheme.accentColor)

                Text("Join the Race")
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                Text("Enter the race code to track\nyour runner in real time.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Input fields
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Race Code")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("e.g. GOZO2026", text: $inputCode)
                        .font(.system(.title2, design: .monospaced).bold())
                        .multilineTextAlignment(.center)
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Name")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("e.g. Fiona", text: $inputName)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 32)

            // Join button
            Button {
                let code = inputCode.isEmpty ? "GOZO2026" : inputCode.uppercased()
                let name = inputName.isEmpty ? "Spectator" : inputName
                raceCode = code
                spectatorName = name
                onJoin(code, name)
            } label: {
                HStack {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                    Text("Start Watching")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(themeManager.selectedTheme.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .onAppear {
            inputCode = raceCode
            inputName = spectatorName
        }
    }
}
