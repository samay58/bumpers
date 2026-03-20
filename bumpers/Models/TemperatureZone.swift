//
//  TemperatureZone.swift
//  bumpers
//
//  Temperature zones based on deviation from target bearing.
//

import SwiftUI

enum TemperatureZone: String, CaseIterable {
    case hot        // 0° - 20°   — on track
    case warm       // 20° - 45°  — slight veer
    case cool       // 45° - 90°  — veering
    case cold       // 90° - 135° — off course
    case freezing   // 135° - 180° — wrong way

    // MARK: - Deviation Thresholds

    /// Maximum deviation (absolute) for this zone.
    var maxDeviation: Double {
        switch self {
        case .hot: return 20
        case .warm: return 45
        case .cool: return 90
        case .cold: return 135
        case .freezing: return 180
        }
    }

    /// Determine zone from absolute deviation (0-180).
    static func from(absoluteDeviation: Double) -> TemperatureZone {
        let dev = abs(absoluteDeviation)

        if dev <= 20 { return .hot }
        if dev <= 45 { return .warm }
        if dev <= 90 { return .cool }
        if dev <= 135 { return .cold }
        return .freezing
    }

    // MARK: - Haptic Timing

    /// Interval between haptic pulses in seconds.
    var hapticInterval: TimeInterval {
        switch self {
        case .hot: return 5.0
        case .warm: return 3.5
        case .cool: return 2.0
        case .cold: return 1.2
        case .freezing: return 0.7
        }
    }

    // MARK: - Colors

    /// Gradient colors for the orb (inner, outer).
    var colors: (inner: Color, outer: Color) {
        switch self {
        case .hot: return Theme.hot
        case .warm: return Theme.warm
        case .cool: return Theme.cool
        case .cold: return Theme.cold
        case .freezing: return Theme.freezing
        }
    }

    // MARK: - Visual Properties

    /// Whether this zone requires urgent visual feedback.
    /// Used for steeper gradient falloff and snappier animations.
    var isUrgent: Bool {
        switch self {
        case .hot, .warm, .cool: return false
        case .cold, .freezing: return true
        }
    }

    /// Zone-responsive pulse scale — more dramatic when off course.
    var pulseScale: CGFloat {
        switch self {
        case .hot: return 1.02
        case .warm: return 1.025
        case .cool: return 1.03
        case .cold: return 1.04
        case .freezing: return 1.05
        }
    }

    /// Zone-responsive spring animation — snappier when urgent.
    var bumpSpring: Animation {
        switch self {
        case .hot:
            return .spring(response: 0.35, dampingFraction: 0.75)
        case .warm:
            return .spring(response: 0.3, dampingFraction: 0.72)
        case .cool:
            return .spring(response: 0.25, dampingFraction: 0.68)
        case .cold:
            return .spring(response: 0.2, dampingFraction: 0.62)
        case .freezing:
            return .spring(response: 0.15, dampingFraction: 0.55)
        }
    }

    /// Gradient falloff position — steeper for urgent zones.
    var gradientFalloff: Double {
        isUrgent ? Theme.OrbGradient.falloffUrgent : Theme.OrbGradient.falloffRelaxed
    }

    // MARK: - Display

    var displayName: String {
        switch self {
        case .hot: return "On Track"
        case .warm: return "Slight Veer"
        case .cool: return "Veering"
        case .cold: return "Off Course"
        case .freezing: return "Wrong Way"
        }
    }

    var emoji: String {
        switch self {
        case .hot: return "🔥"
        case .warm: return "🌡️"
        case .cool: return "🌤️"
        case .cold: return "❄️"
        case .freezing: return "🥶"
        }
    }
}
