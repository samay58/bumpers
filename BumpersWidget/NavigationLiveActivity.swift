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
            // MARK: - Lock Screen View

            LockScreenView(
                destinationName: context.attributes.destinationName,
                state: context.state
            )

        } dynamicIsland: { context in
            // MARK: - Dynamic Island Views

            DynamicIsland {
                // Expanded view (long-press)
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.distanceString)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(WidgetTheme.zoneColor(context.state.zone))
                        Text(context.state.zoneDisplayName)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    ZStack {
                        Circle()
                            .fill(WidgetTheme.zoneColor(context.state.zone).opacity(0.3))
                            .blur(radius: 20)
                            .frame(width: 56, height: 56)
                        ZoneIndicator(zone: context.state.zone, size: 26)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(WidgetTheme.zoneColor(context.state.zone))
                        Text(context.attributes.destinationName)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(.white.opacity(0.5))
                            .lineLimit(1)
                    }
                }
            } compactLeading: {
                // Compact leading — zone-colored gradient circle
                ZoneIndicator(zone: context.state.zone, size: 20)
            } compactTrailing: {
                // Compact trailing — distance in zone color
                Text(context.state.distanceString)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(WidgetTheme.zoneColor(context.state.zone))
            } minimal: {
                // Minimal — zone-colored filled circle
                ZoneIndicator(zone: context.state.zone, size: 16)
            }
        }
    }
}

// MARK: - Lock Screen View

private struct LockScreenView: View {
    let destinationName: String
    let state: NavigationActivityAttributes.ContentState

    private var zoneColor: Color {
        WidgetTheme.zoneColor(state.zone)
    }

    var body: some View {
        ZStack {
            // Ambient glow layer
            RadialGradient(
                colors: [
                    zoneColor.opacity(0.45),
                    zoneColor.opacity(0.12),
                    Color.clear
                ],
                center: .leading,
                startRadius: 0,
                endRadius: 200
            )

            // Content
            HStack(spacing: 16) {
                // Zone indicator with glow
                ZStack {
                    Circle()
                        .fill(zoneColor.opacity(0.4))
                        .blur(radius: 14)
                        .frame(width: 48, height: 48)
                    ZoneIndicator(zone: state.zone, size: 32)
                }

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.zoneDisplayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)

                    Text(destinationName)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                }

                Spacer()

                // Distance — zone-colored for visual pop
                Text(state.distanceString)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(zoneColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(WidgetTheme.background)
    }
}

// MARK: - Zone Indicator

private struct ZoneIndicator: View {
    let zone: String
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(WidgetTheme.zoneColor(zone))
            .frame(width: size, height: size)
            .shadow(color: WidgetTheme.zoneColor(zone).opacity(0.6), radius: size / 3)
    }
}

// MARK: - Widget Theme

private enum WidgetTheme {
    static let background = Color(red: 0.04, green: 0.04, blue: 0.04) // #0A0A0A

    static func zoneColor(_ zone: String) -> Color {
        switch zone {
        case "hot":
            return Color(red: 0.937, green: 0.267, blue: 0.267) // #EF4444
        case "warm":
            return Color(red: 0.961, green: 0.620, blue: 0.043) // #F59E0B
        case "cool":
            return Color(red: 0.518, green: 0.800, blue: 0.086) // #84CC16
        case "cold":
            return Color(red: 0.024, green: 0.714, blue: 0.831) // #06B6D4
        case "freezing":
            return Color(red: 0.400, green: 0.494, blue: 0.918) // #667EEA
        case "arrived":
            return Color(red: 0.518, green: 0.800, blue: 0.086) // Green for arrival
        default:
            return Color.gray
        }
    }
}

// MARK: - Preview

#Preview("Lock Screen", as: .content, using: NavigationActivityAttributes.preview) {
    NavigationLiveActivity()
} contentStates: {
    NavigationActivityAttributes.ContentState.previewHot
    NavigationActivityAttributes.ContentState.previewCold
}

// MARK: - Preview Data

extension NavigationActivityAttributes {
    static var preview: NavigationActivityAttributes {
        NavigationActivityAttributes(destinationName: "Starbucks Condesa")
    }
}

extension NavigationActivityAttributes.ContentState {
    static var previewHot: NavigationActivityAttributes.ContentState {
        NavigationActivityAttributes.ContentState(zone: "hot", distanceMeters: 245)
    }

    static var previewCold: NavigationActivityAttributes.ContentState {
        NavigationActivityAttributes.ContentState(zone: "cold", distanceMeters: 1240)
    }
}
