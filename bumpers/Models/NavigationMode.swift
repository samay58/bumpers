import CoreLocation

enum NavigationMode: String, CaseIterable, Codable, Identifiable {
    case direct
    case roomToWander
    case scenic

    var id: String { rawValue }

    var label: String {
        switch self {
        case .direct: return "Direct"
        case .roomToWander: return "Room to wander"
        case .scenic: return "Scenic"
        }
    }

    var subtitle: String {
        switch self {
        case .direct: return "Keep me close"
        case .roomToWander: return "Give me space"
        case .scenic: return "Let me drift"
        }
    }

    var baselineWidthMeters: CLLocationDistance {
        switch self {
        case .direct: return 35
        case .roomToWander: return 75
        case .scenic: return 125
        }
    }
}
