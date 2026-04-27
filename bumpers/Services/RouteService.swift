import CoreLocation
import MapKit

enum RouteServiceError: Error {
    case noRoutes
}

final class RouteService {

    func walkingRoutes(
        from source: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) async throws -> [WalkingRoute] {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .walking
        request.requestsAlternateRoutes = true

        let directions = MKDirections(request: request)
        let response: MKDirections.Response = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<MKDirections.Response, Error>) in
                directions.calculate { response, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let response else {
                        continuation.resume(throwing: RouteServiceError.noRoutes)
                        return
                    }
                    continuation.resume(returning: response)
                }
            }
        } onCancel: {
            directions.cancel()
        }

        let routes = response.routes.map {
            WalkingRoute(
                polyline: $0.polyline,
                expectedTravelTime: $0.expectedTravelTime,
                distance: $0.distance,
                steps: $0.steps
            )
        }

        guard !routes.isEmpty else {
            throw RouteServiceError.noRoutes
        }

        return routes
    }
}
