import Foundation

struct FieldModeSettings: Equatable {
    let isEnabled: Bool
    let hapticProfile: HapticProfile

    static let validationDefault = FieldModeSettings(
        isEnabled: true,
        hapticProfile: .fieldMax
    )

    static let productDefault = FieldModeSettings(
        isEnabled: false,
        hapticProfile: .pocketNormal
    )
}

struct FieldOrbSignal: Equatable {
    let shift: Double
    let isAlive: Bool
    let isDirectionalCorrection: Bool

    static func make(
        instruction: CorrectionInstruction,
        deviation: Double,
        fieldModeEnabled: Bool
    ) -> FieldOrbSignal {
        if let direction = instruction.correctionDirection {
            let magnitude = max(0.2, min(1, instruction.urgency))
            return FieldOrbSignal(
                shift: direction == .right ? magnitude : -magnitude,
                isAlive: true,
                isDirectionalCorrection: true
            )
        }

        guard fieldModeEnabled else {
            return FieldOrbSignal(shift: 0, isAlive: false, isDirectionalCorrection: false)
        }

        switch instruction.state {
        case .inLane:
            let liveBias = max(-0.18, min(0.18, deviation / 360))
            return FieldOrbSignal(shift: liveBias, isAlive: true, isDirectionalCorrection: false)
        case .simpleGuidance:
            let liveBias = max(-0.35, min(0.35, deviation / 240))
            return FieldOrbSignal(shift: liveBias, isAlive: true, isDirectionalCorrection: false)
        case .acquiringLocation, .lowConfidence:
            return FieldOrbSignal(shift: 0, isAlive: true, isDirectionalCorrection: false)
        case .arrived:
            return FieldOrbSignal(shift: 0, isAlive: true, isDirectionalCorrection: false)
        case .drifting, .offCourse, .wrongWay:
            return FieldOrbSignal(shift: 0, isAlive: true, isDirectionalCorrection: false)
        }
    }
}

enum FieldModeDiagnostics {
    static func text(
        instruction: CorrectionInstruction,
        hapticProfile: HapticProfile,
        lastHapticAge: TimeInterval?,
        cooldown: TimeInterval,
        headingAvailable: Bool
    ) -> String {
        let state = stateLabel(for: instruction, headingAvailable: headingAvailable)
        let buzz = buzzLabel(lastHapticAge)
        let cooldownText = cooldown > 0 ? "cooldown \(String(format: "%.1f", cooldown))s" : "no cooldown"
        return "\(state) - \(hapticProfile.displayName) - \(buzz) - \(cooldownText)"
    }

    private static func stateLabel(
        for instruction: CorrectionInstruction,
        headingAvailable: Bool
    ) -> String {
        switch instruction.state {
        case .acquiringLocation:
            return "Finding location"
        case .lowConfidence(.poorLocationAccuracy):
            return "GPS uncertain"
        case .lowConfidence(.headingUnavailable):
            return headingAvailable ? "Calibrating direction" : "Need walking direction"
        case .lowConfidence(.locationUnavailable):
            return "Location unavailable"
        case .inLane:
            return "In lane"
        case .drifting(let direction, _):
            return "Drifting \(direction.label)"
        case .offCourse(let direction, _):
            return "Off course \(direction.label)"
        case .wrongWay:
            return "Wrong way"
        case .arrived:
            return "Arrived"
        case .simpleGuidance:
            return "Simple guidance"
        }
    }

    private static func buzzLabel(_ lastHapticAge: TimeInterval?) -> String {
        guard let lastHapticAge else {
            return "no buzz yet"
        }
        return "buzz \(Int(lastHapticAge.rounded()))s ago"
    }
}
