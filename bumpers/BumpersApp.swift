//
//  BumpersApp.swift
//  bumpers
//
//  Hot/cold navigation app — guides you with haptics, not routes.
//

import SwiftUI
import SwiftData

@main
struct BumpersApp: App {

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
            // For v1: Go straight to navigation with hardcoded destination
            NavigationView(
                viewModel: NavigationViewModel(
                    destination: .testDestination
                )
            )
        }
        .modelContainer(sharedModelContainer)
    }
}
