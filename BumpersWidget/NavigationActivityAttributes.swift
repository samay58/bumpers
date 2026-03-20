//
//  NavigationActivityAttributes.swift
//  bumpers
//
//  Shared model for Live Activity — used by main app and widget extension.
//  Add this file to BOTH targets.
//

import ActivityKit
import Foundation

struct NavigationActivityAttributes: ActivityAttributes {

    // MARK: - Static Properties (set once at start)

    /// Destination name to display
    let destinationName: String

    // MARK: - Dynamic Content State

    struct ContentState: Codable, Hashable {
        /// Current temperature zone: "hot", "warm", "cool", "cold", "freezing"
        let zone: String

        /// Distance to destination in meters
        let distanceMeters: Double

        /// Zone display name for UI: "On Track", "Slight Veer", etc.
        var zoneDisplayName: String {
            switch zone {
            case "hot": return "On Track"
            case "warm": return "Slight Veer"
            case "cool": return "Veering"
            case "cold": return "Off Course"
            case "freezing": return "Wrong Way"
            default: return "Navigating"
            }
        }

        /// Formatted distance string — locale-aware (miles in US, km elsewhere)
        var distanceString: String {
            let measurement = Measurement(value: distanceMeters, unit: UnitLength.meters)
            let formatter = MeasurementFormatter()
            formatter.unitOptions = .naturalScale
            formatter.numberFormatter.maximumFractionDigits = 1
            return formatter.string(from: measurement)
        }
    }
}
