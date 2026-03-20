//
//  JourneyMapView.swift
//  bumpers
//
//  Minimal MapKit visualization of the journey trail.
//

import SwiftUI
import MapKit

struct JourneyMapView: View {
    let journey: Journey

    @State private var position: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $position, interactionModes: []) {
            // Trail polylines (colored by zone)
            ForEach(TemperatureZone.allCases, id: \.self) { zone in
                if let segments = journey.segmentsByZone[zone] {
                    ForEach(Array(segments.enumerated()), id: \.offset) { _, coords in
                        MapPolyline(coordinates: coords)
                            .stroke(zone.colors.inner, lineWidth: 3)
                    }
                }
            }

            // Crow-flies dashed line
            if let start = journey.startCoordinate {
                MapPolyline(coordinates: [start, journey.destination.coordinate])
                    .stroke(
                        Color.white.opacity(0.25),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
            }

            // Start point
            if let start = journey.startCoordinate {
                Annotation("", coordinate: start) {
                    Circle()
                        .fill(Theme.textSecondary)
                        .frame(width: 8, height: 8)
                }
            }

            // End point (destination)
            Annotation("", coordinate: journey.destination.coordinate) {
                Circle()
                    .fill(Theme.hot.inner)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                    )
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .colorScheme(.dark)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .onAppear {
            position = .region(mapRegion)
        }
    }

    // MARK: - Map Region

    private var mapRegion: MKCoordinateRegion {
        let allCoords = journey.points.map { $0.coordinate } + [journey.destination.coordinate]

        guard !allCoords.isEmpty else {
            return MKCoordinateRegion(
                center: journey.destination.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }

        let minLat = allCoords.map { $0.latitude }.min()!
        let maxLat = allCoords.map { $0.latitude }.max()!
        let minLon = allCoords.map { $0.longitude }.min()!
        let maxLon = allCoords.map { $0.longitude }.max()!

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        // Add 40% padding for comfortable viewing
        let latDelta = (maxLat - minLat) * 1.4
        let lonDelta = (maxLon - minLon) * 1.4

        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(
                latitudeDelta: max(latDelta, 0.005),
                longitudeDelta: max(lonDelta, 0.005)
            )
        )
    }
}
