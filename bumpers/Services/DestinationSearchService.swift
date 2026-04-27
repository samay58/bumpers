import CoreLocation
import MapKit

@MainActor
protocol DestinationSearchProviding {
    func suggestions(for query: String, near location: CLLocation?) async throws -> [SearchSuggestion]
    func search(query: String, near location: CLLocation?) async throws -> [SearchResult]
}

@MainActor
final class DestinationSearchService: NSObject, DestinationSearchProviding {
    private let completer = MKLocalSearchCompleter()
    private var suggestionContinuation: CheckedContinuation<[SearchSuggestion], Error>?
    private var activeSearch: MKLocalSearch?

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest, .query]
    }

    func suggestions(for query: String, near location: CLLocation?) async throws -> [SearchSuggestion] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        if let location {
            completer.region = region(centeredOn: location.coordinate, radiusMeters: 5_000)
        }
        completer.queryFragment = query

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[SearchSuggestion], Error>) in
            suggestionContinuation?.resume(returning: [])
            suggestionContinuation = continuation
        }
    }

    func search(query: String, near location: CLLocation?) async throws -> [SearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        activeSearch?.cancel()

        let localResults = try await performSearch(query: trimmed, near: location, radiusMeters: 5_000)
        if !localResults.isEmpty {
            return localResults
        }

        return try await performSearch(query: trimmed, near: location, radiusMeters: 25_000)
    }

    private func performSearch(query: String, near location: CLLocation?, radiusMeters: CLLocationDistance) async throws -> [SearchResult] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.address, .pointOfInterest]
        if let location {
            request.region = region(centeredOn: location.coordinate, radiusMeters: radiusMeters)
        }

        let search = MKLocalSearch(request: request)
        activeSearch = search

        let response: [MKMapItem] = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[MKMapItem], Error>) in
                search.start { response, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: response?.mapItems ?? [])
                }
            }
        } onCancel: {
            search.cancel()
        }

        if activeSearch === search {
            activeSearch = nil
        }

        return response.prefix(8).map { item in
            let distance = location.map {
                CLLocation(latitude: item.placemark.coordinate.latitude, longitude: item.placemark.coordinate.longitude)
                    .distance(from: $0)
            }
            return SearchResult(
                title: item.name ?? "Unknown",
                subtitle: Self.formatAddress(item.placemark),
                coordinate: item.placemark.coordinate,
                distanceMeters: distance,
                mapItemIdentifierRawValue: Self.identifierString(for: item)
            )
        }
    }

    private func region(centeredOn coordinate: CLLocationCoordinate2D, radiusMeters: CLLocationDistance) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: radiusMeters * 2,
            longitudinalMeters: radiusMeters * 2
        )
    }

    static func formatAddress(_ placemark: MKPlacemark) -> String {
        var components: [String] = []

        if let number = placemark.subThoroughfare, let street = placemark.thoroughfare {
            components.append("\(number) \(street)")
        } else if let street = placemark.thoroughfare {
            components.append(street)
        }

        if let locality = placemark.locality {
            components.append(locality)
        }

        return components.joined(separator: ", ")
    }

    static func identifierString(for item: MKMapItem) -> String? {
        if #available(iOS 18.0, *) {
            return item.identifier?.rawValue
        }
        return nil
    }
}

extension DestinationSearchService: @MainActor MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let suggestions = completer.results.prefix(8).map {
            SearchSuggestion(id: "\($0.title)-\($0.subtitle)", title: $0.title, subtitle: $0.subtitle)
        }
        suggestionContinuation?.resume(returning: Array(suggestions))
        suggestionContinuation = nil
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        suggestionContinuation?.resume(throwing: error)
        suggestionContinuation = nil
    }
}
