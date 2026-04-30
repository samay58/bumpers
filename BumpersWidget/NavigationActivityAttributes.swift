//
//  NavigationActivityAttributes.swift
//  bumpers
//
//  Shared model for Live Activity, used by main app and widget extension.
//  Add this file to BOTH targets.
//

import ActivityKit
import Foundation

struct NavigationActivityAttributes: ActivityAttributes {

    // MARK: - Static Properties

    let destinationName: String

    // MARK: - Dynamic Content State

    struct ContentState: Codable, Hashable {
        let zone: String
        let distanceMeters: Double
        let distanceAvailable: Bool
        let status: String
        let action: String
        let direction: String?
        let guidanceMode: String
        let confidence: Double
        let updatedAt: Date

        init(
            zone: String,
            distanceMeters: Double,
            distanceAvailable: Bool = true,
            status: String? = nil,
            action: String? = nil,
            direction: String? = nil,
            guidanceMode: String = "route",
            confidence: Double = 1,
            updatedAt: Date = Date()
        ) {
            self.zone = zone
            self.distanceMeters = distanceMeters
            self.distanceAvailable = distanceAvailable
            self.status = status ?? Self.defaultStatus(for: zone)
            self.action = action ?? Self.defaultAction(for: zone)
            self.direction = direction
            self.guidanceMode = guidanceMode
            self.confidence = max(0, min(1, confidence))
            self.updatedAt = updatedAt
        }

        var zoneDisplayName: String {
            Self.defaultStatus(for: zone)
        }

        var distanceString: String {
            guard distanceAvailable else { return "--" }

            let measurement = Measurement(value: distanceMeters, unit: UnitLength.meters)
            let formatter = MeasurementFormatter()
            formatter.unitOptions = .naturalScale
            formatter.numberFormatter.maximumFractionDigits = 1
            return formatter.string(from: measurement)
        }

        var compactDistanceString: String {
            guard distanceAvailable else { return "--" }

            if distanceMeters < 100 {
                return "\(Int((distanceMeters / 5).rounded() * 5))m"
            }
            if distanceMeters < 1_000 {
                return "\(Int((distanceMeters / 10).rounded() * 10))m"
            }
            return distanceString
        }

        var guidanceDisplayName: String {
            switch guidanceMode {
            case "simple": return "Simple guidance"
            case "lowConfidence": return "Signal low"
            case "acquiring": return "Getting oriented"
            case "arrived": return "Arrived"
            default: return "Route corridor"
            }
        }

        var directionSymbolName: String {
            switch direction {
            case "left": return "arrow.turn.up.left"
            case "right": return "arrow.turn.up.right"
            default:
                switch guidanceMode {
                case "lowConfidence", "acquiring": return "location.slash"
                case "arrived": return "checkmark"
                default: return "circle.fill"
                }
            }
        }

        var distanceBucket: Int {
            guard distanceAvailable else { return -1 }

            let size: Double
            if distanceMeters < 200 {
                size = 10
            } else if distanceMeters < 1_000 {
                size = 25
            } else {
                size = 50
            }
            return Int((distanceMeters / size).rounded(.down))
        }

        var confidenceBucket: Int {
            Int((confidence * 10).rounded(.down))
        }

        private static func defaultStatus(for zone: String) -> String {
            switch zone {
            case "hot": return "In lane"
            case "warm": return "Slight drift"
            case "cool": return "Drifting"
            case "cold": return "Off course"
            case "freezing": return "Moving away"
            case "arrived": return "Arrived"
            default: return "Navigating"
            }
        }

        private static func defaultAction(for zone: String) -> String {
            switch zone {
            case "hot": return "Quiet means on track"
            case "warm": return "Ease back toward the route"
            case "cool": return "Use the next correction"
            case "cold": return "Correct soon"
            case "freezing": return "Turn back toward the route"
            case "arrived": return "You made it"
            default: return "Stay with the signal"
            }
        }
    }
}
