import SwiftUI

struct RaceCompleteView: View {
    let distance: String
    let time: String
    let pace: String
    let elevation: String
    let cheerCount: Int

    @EnvironmentObject var themeManager: ThemeManager
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            themeManager.selectedTheme.backgroundColor.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer().frame(height: 40)

                    // Celebration header
                    VStack(spacing: 12) {
                        Image(systemName: "flag.checkered.2.crossed")
                            .font(.system(size: 60))
                            .foregroundStyle(themeManager.selectedTheme.accentColor)
                            .symbolEffect(.bounce, value: showConfetti)

                        Text("FINISHED!")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Text("Gozo Half Marathon 2026")
                            .font(.title3)
                            .foregroundStyle(.secondary)

                        Text("Incredible run, Mattie.")
                            .font(.headline)
                            .foregroundStyle(themeManager.selectedTheme.accentColor)
                    }

                    // Stats grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(icon: "figure.run", label: "Distance", value: distance, accent: themeManager.selectedTheme.accentColor)
                        StatCard(icon: "stopwatch", label: "Time", value: time, accent: themeManager.selectedTheme.accentColor)
                        StatCard(icon: "gauge.with.dots.needle.33percent", label: "Pace", value: pace, accent: themeManager.selectedTheme.accentColor)
                        StatCard(icon: "mountain.2", label: "Elevation", value: elevation, accent: themeManager.selectedTheme.accentColor)
                    }
                    .padding(.horizontal)

                    // Cheers received
                    if cheerCount > 0 {
                        VStack(spacing: 8) {
                            Text("\(cheerCount)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(themeManager.selectedTheme.accentColor)
                            Text("cheers received")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }

                    // Closing message
                    VStack(spacing: 8) {
                        Text("From the house on Triq il-Knisja,")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("with all our love.")
                            .font(.headline)
                            .foregroundStyle(themeManager.selectedTheme.accentColor)
                    }
                    .padding(.top, 16)

                    Spacer()
                }
            }
        }
        .onAppear { showConfetti = true }
    }
}

private struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    let accent: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(accent)
            Text(value)
                .font(.system(.title3, design: .monospaced).bold())
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
