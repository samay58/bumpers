//
//  JourneyPoint.swift
//  bumpers
//
//  A single sampled point along the journey trail.
//

import Foundation
import CoreLocation

struct JourneyPoint: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let timestamp: Date
    let zone: TemperatureZone
    let distanceToDestination: CLLocationDistance

    /// CLLocation for distance calculations
    var location: CLLocation {
        CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}
