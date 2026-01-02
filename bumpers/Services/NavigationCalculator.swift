//
//  NavigationCalculator.swift
//  bumpers
//
//  Navigation math utilities for bearing, deviation, and distance calculations.
//

import Foundation
import CoreLocation

struct NavigationCalculator {

    /// Walking speed assumption: 5 km/h = 1.39 m/s
    static let walkingSpeedMetersPerSecond: Double = 1.39

    /// Arrival radius in meters
    static let arrivalRadius: CLLocationDistance = 50

    /// Calculate bearing from one coordinate to another.
    /// Returns degrees (0° = north, 90° = east, 180° = south, 270° = west)
    static func bearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude.toRadians
        let lon1 = from.longitude.toRadians
        let lat2 = to.latitude.toRadians
        let lon2 = to.longitude.toRadians

        let dLon = lon2 - lon1

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)

        let radiansBearing = atan2(y, x)

        // Convert to degrees and normalize to 0-360
        var degrees = radiansBearing.toDegrees
        if degrees < 0 {
            degrees += 360
        }

        return degrees
    }

    /// Normalize an angle to the range -180 to 180.
    /// This makes it easy to determine "turn left" vs "turn right".
    static func normalizeAngle(_ angle: Double) -> Double {
        var normalized = angle.truncatingRemainder(dividingBy: 360)
        if normalized > 180 {
            normalized -= 360
        } else if normalized < -180 {
            normalized += 360
        }
        return normalized
    }

    /// Calculate deviation between current heading and target bearing.
    /// Returns a value from -180 to 180:
    /// - Positive = need to turn right
    /// - Negative = need to turn left
    /// - 0 = perfectly on track
    static func deviation(currentHeading: Double, targetBearing: Double) -> Double {
        let diff = targetBearing - currentHeading
        return normalizeAngle(diff)
    }

    /// Absolute deviation (0 to 180), ignoring direction.
    static func absoluteDeviation(currentHeading: Double, targetBearing: Double) -> Double {
        return abs(deviation(currentHeading: currentHeading, targetBearing: targetBearing))
    }

    /// Estimate walking time in seconds for a given distance.
    static func estimatedWalkingTime(meters: CLLocationDistance) -> TimeInterval {
        return meters / walkingSpeedMetersPerSecond
    }

    /// Calculate distance between two coordinates in meters.
    static func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let location1 = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let location2 = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return location1.distance(from: location2)
    }

    /// Check if within arrival radius.
    static func hasArrived(current: CLLocationCoordinate2D, destination: CLLocationCoordinate2D) -> Bool {
        return distance(from: current, to: destination) <= arrivalRadius
    }

    /// Calculate wander budget (extra time available beyond minimum walking time).
    /// Returns nil if no arrival time is set.
    static func wanderBudget(
        currentLocation: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        arrivalTime: Date?
    ) -> TimeInterval? {
        guard let arrivalTime = arrivalTime else { return nil }

        let distanceMeters = distance(from: currentLocation, to: destination)
        let walkingTime = estimatedWalkingTime(meters: distanceMeters)
        let availableTime = arrivalTime.timeIntervalSinceNow

        return max(0, availableTime - walkingTime)
    }
}

// MARK: - Angle Extensions

private extension Double {
    var toRadians: Double {
        return self * .pi / 180
    }

    var toDegrees: Double {
        return self * 180 / .pi
    }
}
