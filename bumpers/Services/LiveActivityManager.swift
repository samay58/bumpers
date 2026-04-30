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
    private var lastSnapshot: NavigationActivitySnapshot?
    private var lastUpdateSentAt: Date?

    private enum UpdateTiming {
        static let staleInterval: TimeInterval = 45
        static let heartbeatInterval: TimeInterval = 25
    }

    /// Whether Live Activities are supported on this device
    var isSupported: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    // MARK: - Activity Lifecycle

    /// Start a new navigation Live Activity.
    func startNavigation(
        destinationName: String,
        initialState: NavigationActivityAttributes.ContentState
    ) {
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

        // Request the activity
        do {
            let activity = try Activity<NavigationActivityAttributes>.request(
                attributes: attributes,
                content: .init(
                    state: initialState,
                    staleDate: Date().addingTimeInterval(UpdateTiming.staleInterval)
                ),
                pushType: nil // Local updates only, no push notifications
            )
            currentActivity = activity
            lastSnapshot = NavigationActivitySnapshot(state: initialState)
            lastUpdateSentAt = Date()
            print("[LiveActivityManager] Started navigation activity: \(activity.id)")
        } catch {
            print("[LiveActivityManager] Failed to start activity: \(error)")
        }
    }

    /// Backward-compatible starter for older call sites and previews.
    func startNavigation(destinationName: String, zone: TemperatureZone, distance: Double) {
        startNavigation(
            destinationName: destinationName,
            initialState: NavigationActivityAttributes.ContentState(
                zone: zone.rawValue,
                distanceMeters: distance
            )
        )
    }

    /// Update the Live Activity with new navigation state.
    func updateNavigation(
        _ state: NavigationActivityAttributes.ContentState,
        force: Bool = false
    ) {
        guard let activity = currentActivity else { return }
        guard shouldSend(state, force: force, now: Date()) else { return }

        lastSnapshot = NavigationActivitySnapshot(state: state)
        lastUpdateSentAt = Date()
        Task {
            await activity.update(
                .init(
                    state: state,
                    staleDate: Date().addingTimeInterval(UpdateTiming.staleInterval)
                )
            )
        }
    }

    /// Backward-compatible updater for older call sites.
    func updateNavigation(zone: TemperatureZone, distance: Double) {
        updateNavigation(
            NavigationActivityAttributes.ContentState(
                zone: zone.rawValue,
                distanceMeters: distance
            )
        )
    }

    /// End the Live Activity (on arrival or cancellation).
    func endNavigation(showFinalState: Bool = true) {
        guard let activity = currentActivity else { return }

        let finalState = NavigationActivityAttributes.ContentState(
            zone: "arrived",
            distanceMeters: 0,
            status: "Arrived",
            action: "You made it",
            guidanceMode: "arrived",
            confidence: 1
        )

        Task {
            await activity.end(
                .init(state: finalState, staleDate: nil),
                dismissalPolicy: showFinalState ? .after(.now.addingTimeInterval(5)) : .immediate
            )
        }

        currentActivity = nil
        lastSnapshot = nil
        lastUpdateSentAt = nil
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
        lastSnapshot = nil
        lastUpdateSentAt = nil
    }

    private func shouldSend(
        _ state: NavigationActivityAttributes.ContentState,
        force: Bool,
        now: Date
    ) -> Bool {
        guard !force else { return true }

        let snapshot = NavigationActivitySnapshot(state: state)
        guard let lastSnapshot else { return true }
        if snapshot != lastSnapshot { return true }

        guard let lastUpdateSentAt else { return true }
        return now.timeIntervalSince(lastUpdateSentAt) >= UpdateTiming.heartbeatInterval
    }
}

private struct NavigationActivitySnapshot: Equatable {
    let zone: String
    let distanceBucket: Int
    let status: String
    let action: String
    let direction: String?
    let guidanceMode: String
    let confidenceBucket: Int

    init(state: NavigationActivityAttributes.ContentState) {
        zone = state.zone
        distanceBucket = state.distanceBucket
        status = state.status
        action = state.action
        direction = state.direction
        guidanceMode = state.guidanceMode
        confidenceBucket = state.confidenceBucket
    }
}
