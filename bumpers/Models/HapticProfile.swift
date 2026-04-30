import Foundation

enum HapticProfile: String, CaseIterable, Codable, Identifiable {
    case fieldMax
    case pocketMax
    case pocketNormal
    case handheld
    case quiet

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fieldMax: return "Field Max"
        case .pocketMax: return "Pocket Max"
        case .pocketNormal: return "Pocket Normal"
        case .handheld: return "Handheld"
        case .quiet: return "Quiet"
        }
    }

    var energyScale: Float {
        switch self {
        case .fieldMax: return 1.18
        case .pocketMax: return 1.0
        case .pocketNormal: return 0.78
        case .handheld: return 0.62
        case .quiet: return 0.42
        }
    }

    var cooldownScale: TimeInterval {
        switch self {
        case .fieldMax: return 0.62
        case .pocketMax: return 0.82
        case .pocketNormal, .handheld, .quiet: return 1.0
        }
    }

    var continuousDurationScale: TimeInterval {
        switch self {
        case .fieldMax: return 1.28
        case .pocketMax: return 1.08
        case .pocketNormal, .handheld, .quiet: return 1.0
        }
    }

    var wrongWayRumbleDuration: TimeInterval {
        switch self {
        case .fieldMax: return 0.58
        case .pocketMax: return 0.50
        case .pocketNormal, .handheld, .quiet: return 0.45
        }
    }

    var allowsOnTrackNod: Bool {
        self != .quiet
    }
}

enum HapticPatternKind: Equatable {
    case none
    case onTrackNod
    case correctLeft(severity: Severity)
    case correctRight(severity: Severity)
    case wrongWay(direction: CorrectionDirection?)
    case arrival
    case lowConfidence
}

enum HapticEventType: Equatable {
    case transient
    case continuous
}

struct HapticEventSpec: Equatable {
    let type: HapticEventType
    let relativeTime: TimeInterval
    let duration: TimeInterval
    let intensity: Float
    let sharpness: Float
    let attackTime: Float?
    let releaseTime: Float?
}

struct HapticPattern: Equatable {
    let kind: HapticPatternKind
    let events: [HapticEventSpec]
    let cooldown: TimeInterval
}
