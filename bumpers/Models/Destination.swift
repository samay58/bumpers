//
//  Destination.swift
//  bumpers
//
//  SwiftData model for navigation destinations.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class Destination {

    // MARK: - Properties

    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var lastUsed: Date
    var mapItemIdentifierRawValue: String?

    // MARK: - Initialization

    init(
        name: String,
        address: String,
        latitude: Double,
        longitude: Double,
        mapItemIdentifierRawValue: String? = nil
    ) {
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.mapItemIdentifierRawValue = mapItemIdentifierRawValue
        self.lastUsed = Date()
    }

    // MARK: - Computed Properties

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    // MARK: - Methods

    func markAsUsed() {
        lastUsed = Date()
    }
}

// MARK: - Test Destination

extension Destination {

    /// Hardcoded test destination: Starbucks Condesa (Temazcal pickup point)
    static let testDestination = Destination(
        name: "Starbucks Condesa",
        address: "Alfonso Reyes 218, Hipódromo Condesa, CDMX",
        latitude: 19.4074986,
        longitude: -99.1738171
    )
}
