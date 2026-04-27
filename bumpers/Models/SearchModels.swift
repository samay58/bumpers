import CoreLocation

struct SearchSuggestion: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
}

struct SearchResult: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
    let distanceMeters: CLLocationDistance?
    let mapItemIdentifierRawValue: String?

    init(
        title: String,
        subtitle: String,
        coordinate: CLLocationCoordinate2D,
        distanceMeters: CLLocationDistance?,
        mapItemIdentifierRawValue: String?
    ) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        self.distanceMeters = distanceMeters
        self.mapItemIdentifierRawValue = mapItemIdentifierRawValue
        self.id = mapItemIdentifierRawValue ?? "\(coordinate.latitude),\(coordinate.longitude)-\(title)"
    }
}

enum SearchState: Equatable {
    case idle
    case typing
    case loading
    case results
    case noResults
    case error(String)
}

enum WalkEstimateState: Equatable {
    case findingLocation
    case estimating
    case directRoute(TimeInterval)
    case roughStraightLine(TimeInterval)
    case unavailable

    var displayText: String {
        switch self {
        case .findingLocation:
            return "Finding your location..."
        case .estimating:
            return "Estimating walk..."
        case .directRoute(let seconds):
            return "Direct walk: \(format(seconds))"
        case .roughStraightLine(let seconds):
            return "Rough estimate: \(format(seconds))"
        case .unavailable:
            return "Unable to estimate yet"
        }
    }

    var seconds: TimeInterval? {
        switch self {
        case .directRoute(let seconds), .roughStraightLine(let seconds):
            return seconds
        case .findingLocation, .estimating, .unavailable:
            return nil
        }
    }

    private func format(_ seconds: TimeInterval) -> String {
        let minutes = max(1, Int(seconds / 60))
        return "~\(minutes) min"
    }
}
