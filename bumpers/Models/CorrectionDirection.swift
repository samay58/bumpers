//
//  CorrectionDirection.swift
//  bumpers
//

enum CorrectionDirection {
    case left   // user should correct left (deviation < 0)
    case right  // user should correct right (deviation > 0)

    var label: String {
        switch self {
        case .left:
            return "left"
        case .right:
            return "right"
        }
    }

    static func from(deviation: Double, deadZone: Double = 0) -> CorrectionDirection? {
        if deviation > deadZone {
            return .right
        }
        if deviation < -deadZone {
            return .left
        }
        return nil
    }
}
