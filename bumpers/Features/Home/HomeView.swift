//
//  HomeView.swift
//  bumpers
//
//  Destination entry screen.
//

import CoreLocation
import SwiftData
import SwiftUI

struct HomeView: View {
    let locationService: LocationService

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Destination.lastUsed, order: .reverse) private var recentDestinations: [Destination]

    @State private var searchViewModel = DestinationSearchViewModel()
    @State private var selectedDestination: Destination?
    @State private var searchResultsAppeared = false
    @State private var glowOpacity: Double = 0.5

    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()

            ambientGlow

            VStack(spacing: 0) {
                header
                    .padding(.top, 80)
                    .padding(.bottom, 36)

                searchField
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.bottom, 28)

                if !searchViewModel.query.isEmpty {
                    searchResultsList
                } else {
                    recentsList
                }

                Spacer()
            }
        }
        .onAppear {
            startGlowPulse()
            locationService.requestPermission()
            locationService.startUpdating()
            searchViewModel.setCurrentLocation(locationService.currentLocation)
        }
        .onChange(of: locationService.currentLocation) { _, newLocation in
            searchViewModel.setCurrentLocation(newLocation)
        }
        .sheet(item: $selectedDestination) { destination in
            WanderDialSheet(destination: destination, locationService: locationService)
        }
    }

    private var ambientGlow: some View {
        GeometryReader { geo in
            RadialGradient(
                colors: [
                    Theme.warm.inner.opacity(glowOpacity * 0.04),
                    Theme.warm.outer.opacity(glowOpacity * 0.015),
                    .clear
                ],
                center: UnitPoint(x: 0.5, y: 0.3),
                startRadius: 0,
                endRadius: geo.size.height * 0.55
            )
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        Text("Where are you headed?")
            .font(Theme.screenTitleFont)
            .foregroundStyle(Theme.textPrimary)
            .multilineTextAlignment(.center)
    }

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.textTertiary)

            TextField(
                "Search places...",
                text: Binding(
                    get: { searchViewModel.query },
                    set: { searchViewModel.updateQuery($0) }
                )
            )
            .font(Theme.quicksand(size: 17, weight: .regular))
            .foregroundStyle(Theme.textPrimary)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)

            if !searchViewModel.query.isEmpty {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        searchViewModel.updateQuery("")
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, 14)
        .background(Theme.surfaceDefault)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(Theme.borderDefault, lineWidth: 1)
        )
    }

    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if searchViewModel.state == .loading {
                    ProgressView()
                        .tint(Theme.warm.inner)
                        .padding(.top, Theme.Spacing.xl)
                } else if searchViewModel.state == .noResults {
                    Text("No nearby results")
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.top, Theme.Spacing.xl)
                }

                ForEach(searchViewModel.suggestions) { suggestion in
                    SearchSuggestionRow(
                        suggestion: suggestion,
                        isResolving: searchViewModel.resolvingSuggestionID == suggestion.id
                    ) {
                        selectSuggestion(suggestion)
                    }
                }

                ForEach(Array(searchViewModel.results.enumerated()), id: \.element.id) { index, result in
                    SearchResultRow(result: result) {
                        selectSearchResult(result)
                    }
                    .staggeredEntrance(index: index, appeared: searchResultsAppeared)
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            withAnimation {
                searchResultsAppeared = true
            }
        }
        .onChange(of: searchViewModel.results.map(\.id)) { _, _ in
            searchResultsAppeared = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation {
                    searchResultsAppeared = true
                }
            }
        }
    }

    private var recentsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !recentDestinations.isEmpty {
                Text("Recent")
                    .font(Theme.sectionHeaderFont)
                    .foregroundStyle(Theme.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .padding(.horizontal, Theme.Spacing.xl)

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(recentDestinations.prefix(10)) { destination in
                            RecentDestinationRow(destination: destination) {
                                selectDestination(destination)
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.xl)
                }
                .scrollIndicators(.hidden)
            } else {
                emptyState
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "mappin.circle")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(Theme.textTertiary)

            Text("Search for a destination")
                .font(Theme.captionFont)
                .foregroundStyle(Theme.textTertiary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func startGlowPulse() {
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            glowOpacity = 1.0
        }
    }

    private func selectSearchResult(_ result: SearchResult) {
        let destination = Destination(
            name: result.title,
            address: result.subtitle,
            latitude: result.coordinate.latitude,
            longitude: result.coordinate.longitude,
            mapItemIdentifierRawValue: result.mapItemIdentifierRawValue
        )

        if let existing = recentDestinations.first(where: {
            abs($0.latitude - destination.latitude) < 0.0001 &&
            abs($0.longitude - destination.longitude) < 0.0001
        }) {
            existing.markAsUsed()
            selectedDestination = existing
        } else {
            modelContext.insert(destination)
            selectedDestination = destination
        }

        searchViewModel.updateQuery("")
    }

    private func selectSuggestion(_ suggestion: SearchSuggestion) {
        Task {
            if let result = await searchViewModel.resolveSuggestion(suggestion) {
                selectSearchResult(result)
            }
        }
    }

    private func selectDestination(_ destination: Destination) {
        destination.markAsUsed()
        selectedDestination = destination
    }
}

#Preview {
    HomeView(locationService: LocationService())
        .modelContainer(for: Destination.self, inMemory: true)
}
