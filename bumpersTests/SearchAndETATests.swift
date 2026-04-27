import CoreLocation
import Testing
@testable import bumpers

@MainActor
struct SearchAndETATests {

    @Test func searchViewModelSuppressesStaleResults() {
        let viewModel = DestinationSearchViewModel(searchService: FakeDestinationSearchService())
        viewModel.query = "devocion"

        viewModel.applyResults(
            [SearchResult(title: "Old Dev", subtitle: "Wrong", coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), distanceMeters: nil, mapItemIdentifierRawValue: nil)],
            for: "dev"
        )
        #expect(viewModel.results.isEmpty)

        viewModel.applyResults(
            [SearchResult(title: "Devoción", subtitle: "Williamsburg", coordinate: CLLocationCoordinate2D(latitude: 40.716, longitude: -73.963), distanceMeters: 120, mapItemIdentifierRawValue: "place-id")],
            for: "devocion"
        )
        #expect(viewModel.results.map(\.title) == ["Devoción"])
    }

    @Test func searchViewModelResolvesSuggestionsToSearchResult() async {
        let result = SearchResult(
            title: "Devoción",
            subtitle: "Williamsburg",
            coordinate: CLLocationCoordinate2D(latitude: 40.716, longitude: -73.963),
            distanceMeters: 120,
            mapItemIdentifierRawValue: "place-id"
        )
        let viewModel = DestinationSearchViewModel(searchService: FakeDestinationSearchService(results: [result]))

        let resolved = await viewModel.resolveSuggestion(
            SearchSuggestion(id: "devocion-williamsburg", title: "Devoción", subtitle: "Williamsburg")
        )

        #expect(resolved?.title == "Devoción")
        #expect(viewModel.resolvingSuggestionID == nil)
    }

    @Test func walkEstimateNeverUsesFakeFifteenMinutes() {
        #expect(WalkEstimateState.findingLocation.displayText == "Finding your location...")
        #expect(WalkEstimateState.estimating.displayText == "Estimating walk...")
        #expect(WalkEstimateState.unavailable.displayText == "Unable to estimate yet")
        #expect(WalkEstimateState.directRoute(620).displayText == "Direct walk: ~10 min")
        #expect(WalkEstimateState.roughStraightLine(620).displayText == "Rough estimate: ~10 min")
    }
}

private struct FakeDestinationSearchService: DestinationSearchProviding {
    var results: [SearchResult] = []

    func suggestions(for query: String, near location: CLLocation?) async throws -> [SearchSuggestion] {
        []
    }

    func search(query: String, near location: CLLocation?) async throws -> [SearchResult] {
        results
    }
}
