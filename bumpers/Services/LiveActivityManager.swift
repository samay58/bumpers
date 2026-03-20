//
//  LiveActivityManager.swift
//  bumpers
//
//  Manages Live Activity lifecycle for navigation — Lock Screen + Dynamic Island.
//

import ActivityKit
import Foundation

@Observable
final class LiveActivityManager {

    // MARK: - State

    private var currentActivity: Activity<NavigationActivityAttributes>?

    /// Whether Live Activities are supported on this device
    var isSupported: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    // MARK: - Activity Lifecycle

    /// Start a new navigation Live Activity.
    func startNavigation(destinationName: String, zone: TemperatureZone, distance: Double) {
        // Check if activities are enabled
        guard isSupported else {
            print("[LiveActivityManager] Live Activities not supported or disabled")
            return
        }

        // End any existing activity first
        if currentActivity != nil {
            endNavigation()
        }

        // Create attributes (static data)
        let attributes = NavigationActivityAttributes(
            destinationName: destinationName
        )

        // Create initial content state (dynamic data)
        let initialState = NavigationActivityAttributes.ContentState(
            zone: zone.rawValue,
            distanceMeters: distance
        )

        // Request the activity
        do {
            let activity = try Activity<NavigationActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: Date().addingTimeInterval(10)),
                pushType: nil // Local updates only, no push notifications
            )
            currentActivity = activity
            print("[LiveActivityManager] Started navigation activity: \(activity.id)")
        } catch {
            print("[LiveActivityManager] Failed to start activity: \(error)")
        }
    }

    /// Update the Live Activity with new navigation state.
    func updateNavigation(zone: TemperatureZone, distance: Double) {
        guard let activity = currentActivity else { return }

        let updatedState = NavigationActivityAttributes.ContentState(
            zone: zone.rawValue,
            distanceMeters: distance
        )

        Task {
            await activity.update(
                .init(state: updatedState, staleDate: Date().addingTimeInterval(10))
            )
        }
    }

    /// End the Live Activity (on arrival or cancellation).
    func endNavigation(showFinalState: Bool = true) {
        guard let activity = currentActivity else { return }

        let finalState = NavigationActivityAttributes.ContentState(
            zone: "arrived",
            distanceMeters: 0
        )

        Task {
            await activity.end(
                .init(state: finalState, staleDate: nil),
                dismissalPolicy: showFinalState ? .after(.now.addingTimeInterval(5)) : .immediate
            )
        }

        currentActivity = nil
        print("[LiveActivityManager] Ended navigation activity")
    }

    /// End all active navigation activities (cleanup on app launch).
    func endAllActivities() {
        Task {
            for activity in Activity<NavigationActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
        currentActivity = nil
    }
}
