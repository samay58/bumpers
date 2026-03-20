//
//  Journey.swift
//  bumpers
//
//  Complete journey data for arrival visualization.
//

import Foundation
import CoreLocation

struct Journey {
    let destination: Destination
    let startTime: Date
    let endTime: Date
    let points: [JourneyPoint]

    // MARK: - Computed Properties

    /// Duration of the journey
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    /// Total distance walked (sum of segments)
    var totalDistance: CLLocationDistance {
        guard points.count > 1 else { return 0 }
        return zip(points, points.dropFirst()).reduce(0) { total, pair in
            total + pair.0.location.distance(from: pair.1.location)
        }
    }

    /// Direct "crow flies" distance from start to destination
    var directDistance: CLLocationDistance {
        guard let first = points.first else { return 0 }
        return NavigationCalculator.distance(
            from: first.coordinate,
            to: destination.coordinate
        )
    }

    /// Wander factor: actual distance / direct distance
    /// Returns 1.0 if direct distance is 0 (already at destination)
    var wanderFactor: Double {
        guard directDistance > 0 else { return 1.0 }
        return totalDistance / directDistance
    }

    /// Start coordinate
    var startCoordinate: CLLocationCoordinate2D? {
        points.first?.coordinate
    }

    /// End coordinate (last recorded point)
    var endCoordinate: CLLocationCoordinate2D? {
        points.last?.coordinate
    }

    // MARK: - Trail Segments

    /// Segments grouped by zone for colored polyline rendering.
    /// Each zone maps to an array of coordinate arrays (one per contiguous segment).
    var segmentsByZone: [TemperatureZone: [[CLLocationCoordinate2D]]] {
        guard points.count > 1 else { return [:] }

        var result: [TemperatureZone: [[CLLocationCoordinate2D]]] = [:]
        var currentSegment: [CLLocationCoordinate2D] = []
        var currentZone: TemperatureZone?

        for point in points {
            if let zone = currentZone, zone == point.zone {
                // Same zone — extend segment
                currentSegment.append(point.coordinate)
            } else {
                // Zone changed — save current segment and start new one
                if let zone = currentZone, currentSegment.count >= 2 {
                    result[zone, default: []].append(currentSegment)
                }
                currentZone = point.zone
                // Include previous point for continuity (no gaps)
                if let lastCoord = currentSegment.last {
                    currentSegment = [lastCoord, point.coordinate]
                } else {
                    currentSegment = [point.coordinate]
                }
            }
        }

        // Save final segment
        if let zone = currentZone, currentSegment.count >= 2 {
            result[zone, default: []].append(currentSegment)
        }

        return result
    }
}
