import Foundation

struct HapticCalibrationService {
    func recommendedProfile(rightResult: CalibrationResult, leftResult: CalibrationResult) -> HapticProfile {
        if rightResult == .clear && leftResult == .clear {
            return .pocketNormal
        }
        if rightResult == .couldNotFeel || leftResult == .couldNotFeel {
            return .pocketMax
        }
        return .pocketMax
    }
}

enum CalibrationResult: String, CaseIterable, Codable {
    case clear
    case tooWeak
    case couldNotFeel
}
