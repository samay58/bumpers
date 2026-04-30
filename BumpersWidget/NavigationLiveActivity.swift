//
//  NavigationLiveActivity.swift
//  BumpersWidget
//
//  Live Activity views for Lock Screen and Dynamic Island.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct NavigationLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NavigationActivityAttributes.self) { context in
            LockScreenView(
                destinationName: context.attributes.destinationName,
                state: context.state
            )
            .activityBackgroundTint(WidgetTheme.background)
            .activitySystemActionForegroundColor(WidgetTheme.accent(context.state.zone))

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    IslandStatusView(state: context.state)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    IslandDistanceView(state: context.state)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    IslandDestinationView(
                        destinationName: context.attributes.destinationName,
                        state: context.state
                    )
                }
            } compactLeading: {
                SignalMark(state: context.state, size: 22)
                    .padding(.leading, 2)
            } compactTrailing: {
                Text(context.state.compactDistanceString)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(WidgetTheme.primaryText)
            } minimal: {
                SignalMark(state: context.state, size: 18)
            }
            .keylineTint(WidgetTheme.accent(context.state.zone))
        }
    }
}

// MARK: - Lock Screen

private struct LockScreenView: View {
    let destinationName: String
    let state: NavigationActivityAttributes.ContentState

    var body: some View {
        ZStack {
            WidgetTheme.background

            LinearGradient(
                colors: [
                    WidgetTheme.accent(state.zone).opacity(0.18),
                    WidgetTheme.background.opacity(0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(spacing: 14) {
                SignalMark(state: state, size: 42)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 7) {
                        Text(state.status)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(WidgetTheme.primaryText)
                            .lineLimit(1)

                        if state.guidanceMode != "route" {
                            GuidanceBadge(text: state.guidanceDisplayName)
                        }
                    }

                    Text(state.action)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(WidgetTheme.secondaryText)
                        .lineLimit(1)

                    HStack(spacing: 5) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(WidgetTheme.accent(state.zone))

                        Text(destinationName)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(WidgetTheme.tertiaryText)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 1) {
                    Text(state.distanceString)
                        .font(.system(size: 23, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(WidgetTheme.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Text("remaining")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(WidgetTheme.tertiaryText)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

// MARK: - Dynamic Island

private struct IslandStatusView: View {
    let state: NavigationActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 9) {
            SignalMark(state: state, size: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(state.status)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(WidgetTheme.primaryText)
                    .lineLimit(1)

                Text(state.action)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(WidgetTheme.secondaryText)
                    .lineLimit(1)
            }
        }
    }
}

private struct IslandDistanceView: View {
    let state: NavigationActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(state.distanceString)
                .font(.system(size: 21, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(WidgetTheme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text("left")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(WidgetTheme.tertiaryText)
        }
    }
}

private struct IslandDestinationView: View {
    let destinationName: String
    let state: NavigationActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 8) {
            GuidanceBadge(text: state.guidanceDisplayName)

            Text(destinationName)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(WidgetTheme.secondaryText)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .padding(.top, 2)
    }
}

// MARK: - Shared Pieces

private struct SignalMark: View {
    let state: NavigationActivityAttributes.ContentState
    let size: CGFloat

    private var accent: Color {
        WidgetTheme.accent(state.zone)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(WidgetTheme.markFill)

            Circle()
                .stroke(accent.opacity(0.7), lineWidth: 1.2)

            Image(systemName: state.directionSymbolName)
                .font(.system(size: symbolSize, weight: .bold))
                .foregroundStyle(accent)
        }
        .frame(width: size, height: size)
        .shadow(color: accent.opacity(0.28), radius: size / 4, x: 0, y: 0)
        .accessibilityLabel(state.status)
    }

    private var symbolSize: CGFloat {
        switch state.directionSymbolName {
        case "circle.fill":
            return size * 0.28
        default:
            return size * 0.43
        }
    }
}

private struct GuidanceBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundStyle(WidgetTheme.secondaryText)
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.09), lineWidth: 1)
            )
    }
}

// MARK: - Widget Theme

private enum WidgetTheme {
    static let background = Color(red: 0.04, green: 0.04, blue: 0.04)
    static let markFill = Color.white.opacity(0.08)
    static let primaryText = Color.white.opacity(0.94)
    static let secondaryText = Color.white.opacity(0.66)
    static let tertiaryText = Color.white.opacity(0.42)

    static func accent(_ zone: String) -> Color {
        switch zone {
        case "hot":
            return Color(red: 0.96, green: 0.45, blue: 0.26)
        case "warm":
            return Color(red: 0.95, green: 0.62, blue: 0.26)
        case "cool":
            return Color(red: 0.52, green: 0.80, blue: 0.34)
        case "cold":
            return Color(red: 0.26, green: 0.72, blue: 0.82)
        case "freezing":
            return Color(red: 0.50, green: 0.58, blue: 0.94)
        case "arrived":
            return Color(red: 0.52, green: 0.80, blue: 0.34)
        default:
            return Color.white.opacity(0.55)
        }
    }
}

// MARK: - Preview

#Preview("Lock Screen", as: .content, using: NavigationActivityAttributes.preview) {
    NavigationLiveActivity()
} contentStates: {
    NavigationActivityAttributes.ContentState.previewInLane
    NavigationActivityAttributes.ContentState.previewCorrection
    NavigationActivityAttributes.ContentState.previewUncertain
}

// MARK: - Preview Data

extension NavigationActivityAttributes {
    static var preview: NavigationActivityAttributes {
        NavigationActivityAttributes(destinationName: "Devocion Williamsburg")
    }
}

extension NavigationActivityAttributes.ContentState {
    static var previewInLane: NavigationActivityAttributes.ContentState {
        NavigationActivityAttributes.ContentState(
            zone: "hot",
            distanceMeters: 245,
            status: "In lane",
            action: "Quiet means on track",
            guidanceMode: "route",
            confidence: 0.95
        )
    }

    static var previewCorrection: NavigationActivityAttributes.ContentState {
        NavigationActivityAttributes.ContentState(
            zone: "cold",
            distanceMeters: 1_240,
            status: "Correct left",
            action: "Take the next useful turn",
            direction: "left",
            guidanceMode: "route",
            confidence: 0.88
        )
    }

    static var previewUncertain: NavigationActivityAttributes.ContentState {
        NavigationActivityAttributes.ContentState(
            zone: "cool",
            distanceMeters: 680,
            status: "GPS uncertain",
            action: "No directional buzz until GPS improves",
            guidanceMode: "lowConfidence",
            confidence: 0.25
        )
    }
}
