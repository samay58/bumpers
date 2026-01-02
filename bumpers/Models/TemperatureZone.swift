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
        case .hot: return 5.0       // Gentle reminder
        case .warm: return 3.0      // Soft nudge
        case .cool: return 2.0      // Noticeable
        case .cold: return 1.5      // Urgent
        case .freezing: return 0.5  // Continuous
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
