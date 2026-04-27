//
//  BumpersApp.swift
//  bumpers
//
//  Route-aware walking app — guides wandering with haptics, not turn-by-turn.
//

import SwiftUI
import SwiftData

@main
struct BumpersApp: App {
    @State private var locationService = LocationService()

    // MARK: - SwiftData Container

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Destination.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            HomeView(locationService: locationService)
        }
        .modelContainer(sharedModelContainer)
    }
}
