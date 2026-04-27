import Foundation

enum Severity: String, CaseIterable, Codable, Equatable {
    case gentle
    case medium
    case strong
    case urgent
}

enum LowConfidenceReason: String, Codable, Equatable {
    case poorLocationAccuracy
    case headingUnavailable
    case locationUnavailable
}

enum CorridorState: Equatable {
    case acquiringLocation
    case lowConfidence(LowConfidenceReason)
    case inLane
    case drifting(direction: CorrectionDirection, severity: Severity)
    case offCourse(direction: CorrectionDirection, severity: Severity)
    case wrongWay(direction: CorrectionDirection?)
    case arrived
    case simpleGuidance(direction: CorrectionDirection?, severity: Severity)
}

struct CorrectionInstruction: Equatable {
    let state: CorridorState
    let correctionDirection: CorrectionDirection?
    let severity: Severity
    let urgency: Double
    let hapticPattern: HapticPatternKind
    let visualTemperature: TemperatureZone
    let confidence: Double
    let usesSimpleGuidance: Bool
}
