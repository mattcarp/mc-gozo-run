import Foundation
import CoreLocation

struct KmMarker: Identifiable {
    let id = UUID()
    let kilometer: Int
    let coordinate: CLLocationCoordinate2D
}

struct WaterStation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

enum POICategory: String {
    case toilet = "Toilets"
    case shower = "Showers"
    case firstAid = "First Aid"
    case marshal = "Marshal"
    case marshalPolice = "Marshal + Police"
    case checkpoint = "Checkpoint"
    case parking = "Parking"
    case music = "Music"
    case turnDirection = "Turn"
}

struct PointOfInterest: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let category: POICategory
    let coordinate: CLLocationCoordinate2D

    var sfSymbol: String {
        switch category {
        case .toilet, .shower:  return "toilet"
        case .firstAid:         return "cross.circle.fill"
        case .marshal:          return "flag.fill"
        case .marshalPolice:    return "shield.fill"
        case .checkpoint:       return "flag.checkered"
        case .parking:          return "p.circle.fill"
        case .music:            return "music.note"
        case .turnDirection:    return "arrow.turn.right.up"
        }
    }
}

final class GPXParser: NSObject, XMLParserDelegate {

    private var trackPoints: [CLLocationCoordinate2D] = []
    private var elevations: [Double] = []
    private var kmMarkers: [KmMarker] = []
    private var waterStations: [WaterStation] = []
    private var pointsOfInterest: [PointOfInterest] = []

    // Current parse state
    private var inTrkseg = false
    private var currentElement = ""
    private var currentLat: Double?
    private var currentLon: Double?
    private var currentEle: Double?
    private var currentName = ""
    private var currentDesc = ""
    private var isWpt = false
    private var eleBuffer = ""

    static func parse(url: URL) -> (trackPoints: [CLLocationCoordinate2D], elevations: [Double], kmMarkers: [KmMarker], waterStations: [WaterStation], pointsOfInterest: [PointOfInterest]) {
        let parser = GPXParser()
        guard let xmlParser = XMLParser(contentsOf: url) else {
            return ([], [], [], [], [])
        }
        xmlParser.delegate = parser
        xmlParser.parse()
        let sorted = parser.kmMarkers.sorted { $0.kilometer < $1.kilometer }
        return (parser.trackPoints, parser.elevations, sorted, parser.waterStations, parser.pointsOfInterest)
    }

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName

        switch elementName {
        case "trkpt":
            inTrkseg = true
            currentLat = Double(attributeDict["lat"] ?? "")
            currentLon = Double(attributeDict["lon"] ?? "")
            currentEle = nil
            eleBuffer = ""
        case "ele":
            eleBuffer = ""
        case "wpt":
            isWpt = true
            currentLat = Double(attributeDict["lat"] ?? "")
            currentLon = Double(attributeDict["lon"] ?? "")
            currentName = ""
            currentDesc = ""
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        switch currentElement {
        case "name":
            currentName += trimmed
        case "desc", "cmt":
            currentDesc += trimmed
        case "ele":
            eleBuffer += trimmed
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
        case "ele":
            currentEle = Double(eleBuffer)

        case "trkpt":
            if let lat = currentLat, let lon = currentLon {
                trackPoints.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
                elevations.append(currentEle ?? 0)
            }
            currentLat = nil
            currentLon = nil
            currentEle = nil
            eleBuffer = ""
            inTrkseg = false

        case "wpt":
            guard let lat = currentLat, let lon = currentLon else {
                isWpt = false
                return
            }
            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let nameLower = currentName.uppercased()
            let descLower = currentDesc.uppercased()

            // Detect water stations
            if currentDesc.contains("Water Station") || currentName.contains("Water Stat") {
                waterStations.append(WaterStation(coordinate: coord))
            }
            // Detect KM markers — names like "1 KM", "2KM", "3 KM" etc
            else if let km = extractKilometer(from: currentName) ?? extractKilometer(from: currentDesc) {
                kmMarkers.append(KmMarker(kilometer: km, coordinate: coord))
            }
            // Detect other POI types
            else if currentDesc.contains("Shower") || currentName.contains("Shower") {
                pointsOfInterest.append(PointOfInterest(name: currentName, detail: currentDesc, category: .shower, coordinate: coord))
            }
            else if currentDesc.contains("Toilet") || currentName.contains("Toilet") {
                pointsOfInterest.append(PointOfInterest(name: currentName, detail: currentDesc, category: .toilet, coordinate: coord))
            }
            else if currentDesc.contains("First Aid") || currentName.contains("First Aid") {
                pointsOfInterest.append(PointOfInterest(name: currentName, detail: currentDesc, category: .firstAid, coordinate: coord))
            }
            else if currentDesc.contains("Police") {
                pointsOfInterest.append(PointOfInterest(name: currentName, detail: currentDesc, category: .marshalPolice, coordinate: coord))
            }
            else if currentDesc.contains("Checkpoint") || currentDesc.contains("checkpoint") {
                pointsOfInterest.append(PointOfInterest(name: currentName, detail: currentDesc, category: .checkpoint, coordinate: coord))
            }
            else if currentDesc.contains("Parking") || currentName.contains("Parking") {
                pointsOfInterest.append(PointOfInterest(name: currentName, detail: currentDesc, category: .parking, coordinate: coord))
            }
            else if currentDesc.contains("Music") || currentName.contains("Music") {
                pointsOfInterest.append(PointOfInterest(name: currentName, detail: currentDesc, category: .music, coordinate: coord))
            }
            else if currentName.contains("Turn") || currentName.contains("Keep") || currentName.contains("At round") {
                pointsOfInterest.append(PointOfInterest(name: currentName, detail: currentDesc, category: .turnDirection, coordinate: coord))
            }
            else if currentDesc.contains("Marshal") {
                pointsOfInterest.append(PointOfInterest(name: currentName, detail: currentDesc, category: .marshal, coordinate: coord))
            }
            _ = nameLower; _ = descLower

            currentLat = nil
            currentLon = nil
            currentName = ""
            currentDesc = ""
            isWpt = false

        default:
            break
        }
    }

    // MARK: - Helpers

    private func extractKilometer(from text: String) -> Int? {
        // Matches: "1 KM", "2KM", "3 KM", "10 KM", "5KM" etc
        // Also matches "FINISH" -> nil, "Marshal" -> nil
        let upper = text.uppercased()
        guard upper.contains("KM") else { return nil }

        // Extract leading integer
        let digits = upper.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }
            .filter { $0 > 0 && $0 <= 21 }
        return digits.first
    }
}
