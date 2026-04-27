import CoreLocation
import MapKit

struct WalkingRoute {
    let polyline: MKPolyline
    let expectedTravelTime: TimeInterval
    let distance: CLLocationDistance
    let steps: [MKRoute.Step]
}

struct CorridorProjection {
    let nearestCoordinate: CLLocationCoordinate2D
    let distanceFromCorridorCenter: CLLocationDistance
    let routeProgress: Double
    let remainingDistanceEstimate: CLLocationDistance
    let routeIndex: Int
}

struct RouteCorridor {
    let routes: [WalkingRoute]
    let mode: NavigationMode
    let baselineWidthMeters: CLLocationDistance
    let destination: CLLocationCoordinate2D

    init(routes: [WalkingRoute], mode: NavigationMode, destination: CLLocationCoordinate2D) {
        self.routes = routes
        self.mode = mode
        self.baselineWidthMeters = mode.baselineWidthMeters
        self.destination = destination
    }

    func width(
        distanceToDestination: CLLocationDistance,
        isMakingProgress: Bool,
        arrivalSlack: TimeInterval?
    ) -> CLLocationDistance {
        var width = baselineWidthMeters

        if let arrivalSlack, arrivalSlack <= 120 {
            width *= 0.5
        } else if isMakingProgress, arrivalSlack == nil || (arrivalSlack ?? 0) > 600 {
            width *= 1.25
        }

        if distanceToDestination < 200 {
            let precisionWidth: CLLocationDistance = min(width, 35)
            let progress = max(0, min(1, distanceToDestination / 200))
            width = precisionWidth + (width - precisionWidth) * progress
        }

        return width
    }

    func nearestPoint(to coordinate: CLLocationCoordinate2D) -> CorridorProjection? {
        let currentPoint = MKMapPoint(coordinate)
        var best: CorridorProjection?

        for (routeIndex, route) in routes.enumerated() {
            let points = route.polyline.points()
            let count = route.polyline.pointCount
            guard count >= 2 else { continue }

            var cumulativeDistance: CLLocationDistance = 0
            var routeLength: CLLocationDistance = 0
            var segmentLengths: [CLLocationDistance] = []

            for index in 0..<(count - 1) {
                let length = points[index].distance(to: points[index + 1])
                segmentLengths.append(length)
                routeLength += length
            }

            for index in 0..<(count - 1) {
                let start = points[index]
                let end = points[index + 1]
                let projection = project(currentPoint, ontoSegmentFrom: start, to: end)
                let distance = currentPoint.distance(to: projection.point)
                let progressDistance = cumulativeDistance + (segmentLengths[index] * projection.t)
                let routeProgress = routeLength > 0 ? progressDistance / routeLength : 0
                let remaining = max(0, routeLength - progressDistance)

                let candidate = CorridorProjection(
                    nearestCoordinate: projection.point.coordinate,
                    distanceFromCorridorCenter: distance,
                    routeProgress: max(0, min(1, routeProgress)),
                    remainingDistanceEstimate: remaining,
                    routeIndex: routeIndex
                )

                if let currentBest = best {
                    if candidate.distanceFromCorridorCenter < currentBest.distanceFromCorridorCenter {
                        best = candidate
                    }
                } else {
                    best = candidate
                }

                cumulativeDistance += segmentLengths[index]
            }
        }

        return best
    }

    private func project(
        _ point: MKMapPoint,
        ontoSegmentFrom start: MKMapPoint,
        to end: MKMapPoint
    ) -> (point: MKMapPoint, t: Double) {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let lengthSquared = dx * dx + dy * dy

        guard lengthSquared > 0 else {
            return (start, 0)
        }

        let rawT = ((point.x - start.x) * dx + (point.y - start.y) * dy) / lengthSquared
        let t = max(0, min(1, rawT))
        return (
            MKMapPoint(x: start.x + (dx * t), y: start.y + (dy * t)),
            t
        )
    }
}
