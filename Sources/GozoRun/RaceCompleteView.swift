import SwiftUI

struct RaceCompleteView: View {
    let distance: String
    let time: String
    let pace: String
    let elevation: String
    let cheerCount: Int

    @EnvironmentObject var themeManager: ThemeManager
    @State private var showConfetti = false
    @State private var confettiPieces: [ConfettiPiece] = []

    var body: some View {
        ZStack {
            themeManager.selectedTheme.backgroundColor.ignoresSafeArea()

            // Confetti layer
            ForEach(confettiPieces) { piece in
                ConfettiView(piece: piece)
            }

            ScrollView {
                VStack(spacing: 32) {
                    Spacer().frame(height: 40)

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

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(icon: "figure.run", label: "Distance", value: distance, accent: themeManager.selectedTheme.accentColor)
                        StatCard(icon: "stopwatch", label: "Time", value: time, accent: themeManager.selectedTheme.accentColor)
                        StatCard(icon: "gauge.with.dots.needle.33percent", label: "Pace", value: pace, accent: themeManager.selectedTheme.accentColor)
                        StatCard(icon: "mountain.2", label: "Elevation", value: elevation, accent: themeManager.selectedTheme.accentColor)
                    }
                    .padding(.horizontal)

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
        .onAppear {
            showConfetti = true
            launchConfetti()
        }
    }

    private func launchConfetti() {
        let colors: [Color] = [
            themeManager.selectedTheme.accentColor,
            .red, .orange, .yellow, .green, .blue, .purple, .pink, .mint
        ]
        var pieces: [ConfettiPiece] = []
        for i in 0..<60 {
            pieces.append(ConfettiPiece(
                id: i,
                color: colors[i % colors.count],
                startX: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                startY: -20,
                endY: UIScreen.main.bounds.height + 40,
                horizontalDrift: CGFloat.random(in: -80...80),
                delay: Double.random(in: 0...1.5),
                duration: Double.random(in: 2.5...5.0),
                rotation: Double.random(in: 0...720),
                size: CGFloat.random(in: 6...14)
            ))
        }
        confettiPieces = pieces
    }
}

// MARK: - Confetti

struct ConfettiPiece: Identifiable {
    let id: Int
    let color: Color
    let startX: CGFloat
    let startY: CGFloat
    let endY: CGFloat
    let horizontalDrift: CGFloat
    let delay: Double
    let duration: Double
    let rotation: Double
    let size: CGFloat
}

struct ConfettiView: View {
    let piece: ConfettiPiece
    @State private var fallen = false

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(piece.color)
            .frame(width: piece.size, height: piece.size * 0.6)
            .rotationEffect(.degrees(fallen ? piece.rotation : 0))
            .position(
                x: piece.startX + (fallen ? piece.horizontalDrift : 0),
                y: fallen ? piece.endY : piece.startY
            )
            .opacity(fallen ? 0 : 1)
            .onAppear {
                withAnimation(
                    .easeIn(duration: piece.duration)
                    .delay(piece.delay)
                ) {
                    fallen = true
                }
            }
    }
}

// MARK: - Stat card

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
