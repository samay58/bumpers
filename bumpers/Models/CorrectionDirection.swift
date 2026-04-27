//
//  CorrectionDirection.swift
//  bumpers
//

enum CorrectionDirection {
    case left   // user should correct left (deviation < 0)
    case right  // user should correct right (deviation > 0)

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
