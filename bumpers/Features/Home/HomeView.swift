//
//  HomeView.swift
//  bumpers
//
//  Destination entry screen — "Where are you headed?"
//  Subtle ambient glow introduces the visual language.
//

import SwiftUI
import SwiftData
import MapKit

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Destination.lastUsed, order: .reverse) private var recentDestinations: [Destination]

    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var selectedDestination: Destination?
    @State private var showWanderDial = false

    // Staggered entrance for search results
    @State private var searchResultsAppeared = false

    // Subtle glow animation
    @State private var glowOpacity: Double = 0.5

    private let searchCompleter = SearchCompleter()

    var body: some View {
        ZStack {
            // Background
            Theme.background
                .ignoresSafeArea()

            // Subtle ambient glow (hints at navigation orb)
            ambientGlow

            // Content
            VStack(spacing: 0) {
                header
                    .padding(.top, 80)
                    .padding(.bottom, 36)

                searchField
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.bottom, 28)

                if !searchText.isEmpty {
                    searchResultsList
                } else {
                    recentsList
                }

                Spacer()
            }
        }
        .onAppear {
            startGlowPulse()
        }
        .sheet(isPresented: $showWanderDial) {
            if let destination = selectedDestination {
                WanderDialSheet(destination: destination)
            }
        }
    }

    // MARK: - Ambient Glow

    private var ambientGlow: some View {
        GeometryReader { geo in
            RadialGradient(
                colors: [
                    Theme.warm.inner.opacity(glowOpacity * 0.06),
                    Theme.warm.outer.opacity(glowOpacity * 0.02),
                    .clear
                ],
                center: UnitPoint(x: 0.5, y: 0.3),
                startRadius: 0,
                endRadius: geo.size.height * 0.6
            )
        }
        .ignoresSafeArea()
    }

    private func startGlowPulse() {
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            glowOpacity = 1.0
        }
    }

    // MARK: - Header

    private var header: some View {
        Text("Where are you headed?")
            .font(Theme.screenTitleFont)
            .foregroundStyle(Theme.textPrimary)
            .multilineTextAlignment(.center)
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.textTertiary)

            TextField("Search places...", text: $searchText)
                .font(Theme.quicksand(size: 17, weight: .regular))
                .foregroundStyle(Theme.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onChange(of: searchText) { _, newValue in
                    performSearch(query: newValue)
                }

            if !searchText.isEmpty {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        searchText = ""
                        searchResults = []
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

    // MARK: - Search Results

    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(searchResults.enumerated()), id: \.element) { index, item in
                    SearchResultRow(item: item) {
                        selectSearchResult(item)
                    }
                    .staggeredEntrance(index: index, appeared: searchResultsAppeared)
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            // Trigger entrance animation
            withAnimation {
                searchResultsAppeared = true
            }
        }
        .onChange(of: searchResults) { _, _ in
            // Reset and re-trigger animation when results change
            searchResultsAppeared = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation {
                    searchResultsAppeared = true
                }
            }
        }
    }

    // MARK: - Recents List

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

    // MARK: - Empty State

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

    // MARK: - Actions

    private func performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.address, .pointOfInterest]

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            isSearching = false

            if let items = response?.mapItems {
                withAnimation(.easeOut(duration: 0.2)) {
                    searchResults = Array(items.prefix(8))
                }
            }
        }
    }

    private func selectSearchResult(_ item: MKMapItem) {
        let destination = Destination(
            name: item.name ?? "Unknown",
            address: formatAddress(item.placemark),
            latitude: item.placemark.coordinate.latitude,
            longitude: item.placemark.coordinate.longitude
        )

        // Check if this destination already exists
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

        searchText = ""
        searchResults = []
        showWanderDial = true
    }

    private func selectDestination(_ destination: Destination) {
        destination.markAsUsed()
        selectedDestination = destination
        showWanderDial = true
    }

    private func formatAddress(_ placemark: MKPlacemark) -> String {
        var components: [String] = []

        if let street = placemark.thoroughfare {
            if let number = placemark.subThoroughfare {
                components.append("\(street) \(number)")
            } else {
                components.append(street)
            }
        }

        if let locality = placemark.locality {
            components.append(locality)
        }

        return components.joined(separator: ", ")
    }
}

// MARK: - Search Result Row

private struct SearchResultRow: View {
    let item: MKMapItem
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                Image(systemName: item.pointOfInterestCategory != nil ? "mappin.circle.fill" : "location.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.warm.inner)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name ?? "Unknown")
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)

                    if let address = formatAddress(item.placemark) {
                        Text(address)
                            .font(Theme.sectionHeaderFont)
                            .foregroundStyle(Theme.textTertiary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .rowPressable()
    }

    private func formatAddress(_ placemark: MKPlacemark) -> String? {
        var parts: [String] = []

        if let street = placemark.thoroughfare {
            parts.append(street)
        }
        if let locality = placemark.locality {
            parts.append(locality)
        }

        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}

// MARK: - Recent Destination Row

private struct RecentDestinationRow: View {
    let destination: Destination
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 3) {
                    Text(destination.name)
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)

                    Text(destination.address)
                        .font(Theme.sectionHeaderFont)
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .rowPressable()
    }
}

// MARK: - Search Completer (for future autocomplete)

private class SearchCompleter: NSObject, MKLocalSearchCompleterDelegate {
    let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .modelContainer(for: Destination.self, inMemory: true)
}
