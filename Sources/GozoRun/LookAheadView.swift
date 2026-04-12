import SwiftUI
import CoreLocation

struct LookAheadView: View {
    @ObservedObject var viewModel: RunTrackerViewModel
    @EnvironmentObject var themeManager: ThemeManager

    @State private var streetViewImage: UIImage?
    @State private var isLoading = false
    @State private var noDataAvailable = false
    @State private var isExpanded = false
    @State private var lastLoadedCoord: CLLocationCoordinate2D?

    private let lookAheadMeters: Double = 500
    private let reloadThresholdMeters: Double = 100

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.4)) {
                    isExpanded.toggle()
                }
                if isExpanded {
                    Task { await loadStreetView() }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "binoculars.fill")
                    Text("Look Ahead")
                        .font(.caption.bold())
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.6)
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(themeManager.selectedTheme.accentColor.opacity(0.85))
                .clipShape(Capsule())
            }

            if isExpanded {
                Group {
                    if let image = streetViewImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(themeManager.selectedTheme.accentColor.opacity(0.4), lineWidth: 1)
                            )
                            .overlay(alignment: .bottomLeading) {
                                Text("500m ahead")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.black.opacity(0.6))
                                    .clipShape(Capsule())
                                    .padding(8)
                            }
                            .overlay(alignment: .topTrailing) {
                                Image(systemName: "camera.viewfinder")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.7))
                                    .padding(6)
                                    .background(.black.opacity(0.4))
                                    .clipShape(Circle())
                                    .padding(8)
                            }
                    } else if noDataAvailable {
                        VStack(spacing: 8) {
                            Image(systemName: "eye.slash")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            Text("No street imagery here")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Keep running — views ahead!")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onChange(of: viewModel.runnerCoordinate.latitude) { _, _ in
            if isExpanded {
                let aheadCoord = findPointAhead(meters: lookAheadMeters)
                if shouldReload(newCoord: aheadCoord) {
                    Task { await loadStreetView() }
                }
            }
        }
    }

    private func shouldReload(newCoord: CLLocationCoordinate2D) -> Bool {
        guard let last = lastLoadedCoord else { return true }
        let d = CLLocation(latitude: last.latitude, longitude: last.longitude)
            .distance(from: CLLocation(latitude: newCoord.latitude, longitude: newCoord.longitude))
        return d > reloadThresholdMeters
    }

    private func loadStreetView() async {
        isLoading = true
        noDataAvailable = false

        let aheadCoord = findPointAhead(meters: lookAheadMeters)
        let heading = calculateHeading(to: aheadCoord)
        lastLoadedCoord = aheadCoord

        // Try pre-cached image first
        if let cached = StreetViewCache.shared.image(for: aheadCoord) {
            await MainActor.run {
                self.streetViewImage = cached
                self.isLoading = false
            }
            Analytics.shared.trackLookAroundLoad(coordinate: aheadCoord, durationMs: 0, success: true)
            return
        }

        // Fall back to live API
        let start = Date()
        let image = await StreetViewService.shared.fetchImage(
            coordinate: aheadCoord,
            heading: heading,
            size: "600x300",
            fov: 100
        )

        let durationMs = Int(Date().timeIntervalSince(start) * 1000)

        await MainActor.run {
            if let image {
                self.streetViewImage = image
                self.noDataAvailable = false
                Analytics.shared.trackLookAroundLoad(coordinate: aheadCoord, durationMs: durationMs, success: true)
            } else {
                self.streetViewImage = nil
                self.noDataAvailable = true
                Analytics.shared.trackLookAroundLoad(coordinate: aheadCoord, durationMs: durationMs, success: false)
            }
            self.isLoading = false
        }
    }

    private func calculateHeading(to coord: CLLocationCoordinate2D) -> Double {
        let runner = viewModel.runnerCoordinate
        let dLon = (coord.longitude - runner.longitude) * .pi / 180
        let lat1 = runner.latitude * .pi / 180
        let lat2 = coord.latitude * .pi / 180
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x) * 180 / .pi
        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }

    private func findPointAhead(meters: Double) -> CLLocationCoordinate2D {
        let coords = viewModel.routeCoordinates
        guard !coords.isEmpty else { return viewModel.runnerCoordinate }

        let runnerLoc = CLLocation(latitude: viewModel.runnerCoordinate.latitude,
                                    longitude: viewModel.runnerCoordinate.longitude)

        var closestIdx = 0
        var closestDist = Double.greatestFiniteMagnitude
        for (i, c) in coords.enumerated() {
            let d = runnerLoc.distance(from: CLLocation(latitude: c.latitude, longitude: c.longitude))
            if d < closestDist {
                closestDist = d
                closestIdx = i
            }
        }

        var accumulated: Double = 0
        for i in closestIdx..<(coords.count - 1) {
            let a = CLLocation(latitude: coords[i].latitude, longitude: coords[i].longitude)
            let b = CLLocation(latitude: coords[i+1].latitude, longitude: coords[i+1].longitude)
            accumulated += a.distance(from: b)
            if accumulated >= meters {
                return coords[i+1]
            }
        }

        return coords.last ?? viewModel.runnerCoordinate
    }
}

// MARK: - Google Street View Static API

final class StreetViewService {
    static let shared = StreetViewService()

    private let apiKey: String

    private init() {
        self.apiKey = UserDefaults.standard.string(forKey: "google_streetview_key")
            ?? ProcessInfo.processInfo.environment["GOOGLE_STREETVIEW_KEY"]
            ?? ""
    }

    func fetchImage(
        coordinate: CLLocationCoordinate2D,
        heading: Double,
        size: String = "600x300",
        fov: Int = 100,
        pitch: Int = 5
    ) async -> UIImage? {
        guard !apiKey.isEmpty else { return nil }

        let urlString = "https://maps.googleapis.com/maps/api/streetview"
            + "?size=\(size)"
            + "&location=\(coordinate.latitude),\(coordinate.longitude)"
            + "&heading=\(Int(heading))"
            + "&fov=\(fov)"
            + "&pitch=\(pitch)"
            + "&key=\(apiKey)"
            + "&return_error_code=true"

        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
}

// MARK: - Pre-cached Street View Images

final class StreetViewCache {
    static let shared = StreetViewCache()

    private var cache: [String: UIImage] = [:]
    private let cacheDir: URL? = {
        try? FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("streetview", isDirectory: true)
    }()

    private init() {
        loadCachedImages()
    }

    func image(for coordinate: CLLocationCoordinate2D) -> UIImage? {
        let key = cacheKey(coordinate)
        if let mem = cache[key] { return mem }
        return loadFromDisk(key: key)
    }

    func store(image: UIImage, for coordinate: CLLocationCoordinate2D) {
        let key = cacheKey(coordinate)
        cache[key] = image
        saveToDisk(image: image, key: key)
    }

    /// Pre-cache street view images for the entire route
    func precacheRoute(
        coordinates: [CLLocationCoordinate2D],
        intervalMeters: Double = 200,
        progress: @escaping (Int, Int) -> Void
    ) async {
        var points: [(CLLocationCoordinate2D, Double)] = []
        var accumulated: Double = 0

        for i in 0..<(coordinates.count - 1) {
            let a = CLLocation(latitude: coordinates[i].latitude, longitude: coordinates[i].longitude)
            let b = CLLocation(latitude: coordinates[i+1].latitude, longitude: coordinates[i+1].longitude)
            let dist = a.distance(from: b)

            if accumulated == 0 || accumulated >= intervalMeters {
                let dLon = (coordinates[i+1].longitude - coordinates[i].longitude) * .pi / 180
                let lat1 = coordinates[i].latitude * .pi / 180
                let lat2 = coordinates[i+1].latitude * .pi / 180
                let y = sin(dLon) * cos(lat2)
                let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
                let heading = (atan2(y, x) * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)

                points.append((coordinates[i], heading))
                accumulated = 0
            }
            accumulated += dist
        }

        let total = points.count
        for (idx, (coord, heading)) in points.enumerated() {
            if image(for: coord) != nil {
                progress(idx + 1, total)
                continue
            }

            if let img = await StreetViewService.shared.fetchImage(
                coordinate: coord,
                heading: heading
            ) {
                store(image: img, for: coord)
            }

            progress(idx + 1, total)

            // Rate limit: ~2 requests/sec to stay within quota
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
    }

    // MARK: - Disk persistence

    private func cacheKey(_ coord: CLLocationCoordinate2D) -> String {
        String(format: "sv_%.4f_%.4f", coord.latitude, coord.longitude)
    }

    private func loadCachedImages() {
        guard let dir = cacheDir else { return }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    private func loadFromDisk(key: String) -> UIImage? {
        guard let dir = cacheDir else { return nil }
        let file = dir.appendingPathComponent("\(key).jpg")
        guard let data = try? Data(contentsOf: file) else { return nil }
        let image = UIImage(data: data)
        if let image { cache[key] = image }
        return image
    }

    private func saveToDisk(image: UIImage, key: String) {
        guard let dir = cacheDir else { return }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("\(key).jpg")
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: file)
        }
    }
}
