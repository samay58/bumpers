import CoreLocation
import Foundation

@MainActor
@Observable
final class DestinationSearchViewModel {
    var query = ""
    var state: SearchState = .idle
    var suggestions: [SearchSuggestion] = []
    var results: [SearchResult] = []
    var resolvingSuggestionID: SearchSuggestion.ID?

    private let searchService: DestinationSearchProviding
    private let debounceNanoseconds: UInt64
    private var searchTask: Task<Void, Never>?
    private var currentLocation: CLLocation?

    init(
        searchService: DestinationSearchProviding? = nil,
        debounceNanoseconds: UInt64 = 300_000_000
    ) {
        self.searchService = searchService ?? DestinationSearchService()
        self.debounceNanoseconds = debounceNanoseconds
    }

    func setCurrentLocation(_ location: CLLocation?) {
        currentLocation = location
    }

    func updateQuery(_ newValue: String) {
        query = newValue
        searchTask?.cancel()

        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            state = .idle
            suggestions = []
            results = []
            return
        }

        state = .typing
        searchTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: debounceNanoseconds)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                self.state = .loading
            }

            do {
                async let suggestions = searchService.suggestions(for: trimmed, near: currentLocation)
                async let results = searchService.search(query: trimmed, near: currentLocation)
                let resolved = try await (suggestions, results)

                await MainActor.run {
                    self.applySuggestions(resolved.0, for: trimmed)
                    self.applyResults(resolved.1, for: trimmed)
                }
            } catch {
                await MainActor.run {
                    guard self.query == trimmed else { return }
                    self.state = .error("Search failed")
                }
            }
        }
    }

    func applySuggestions(_ newSuggestions: [SearchSuggestion], for searchedQuery: String) {
        guard query.trimmingCharacters(in: .whitespacesAndNewlines) == searchedQuery else { return }
        suggestions = newSuggestions
    }

    func applyResults(_ newResults: [SearchResult], for searchedQuery: String) {
        guard query.trimmingCharacters(in: .whitespacesAndNewlines) == searchedQuery else { return }
        results = newResults
        state = newResults.isEmpty ? .noResults : .results
    }

    func resolveSuggestion(_ suggestion: SearchSuggestion) async -> SearchResult? {
        let resolvedQuery = [suggestion.title, suggestion.subtitle]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: ", ")

        resolvingSuggestionID = suggestion.id
        state = .loading
        defer { resolvingSuggestionID = nil }

        do {
            let resolved = try await searchService.search(query: resolvedQuery, near: currentLocation)
            guard let first = resolved.first else {
                state = .noResults
                return nil
            }
            return first
        } catch {
            state = .error("Search failed")
            return nil
        }
    }
}
