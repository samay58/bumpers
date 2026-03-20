//
//  PermissionView.swift
//  bumpers
//
//  Explains location permission and provides action buttons.
//

import SwiftUI
import CoreLocation

struct PermissionView: View {
    let authorizationStatus: CLAuthorizationStatus
    let onRequestPermission: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.xxl) {
            Spacer()

            // Icon
            Image(systemName: "location.circle")
                .font(.system(size: 64, weight: .ultraLight))
                .foregroundStyle(Theme.warm.inner)

            // Message
            VStack(spacing: Theme.Spacing.md) {
                Text(title)
                    .font(Theme.sheetTitleFont)
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xxl)
            }

            Spacer()

            // Action button
            actionButton
                .padding(.horizontal, Theme.Spacing.xxl)
                .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
    }

    // MARK: - Content

    private var title: String {
        switch authorizationStatus {
        case .denied, .restricted:
            return "Location access needed"
        case .notDetermined:
            return "Enable location"
        default:
            return "Location required"
        }
    }

    private var subtitle: String {
        switch authorizationStatus {
        case .denied, .restricted:
            return "Bumper uses your location to guide you toward your destination. Please enable location access in Settings."
        case .notDetermined:
            return "Bumper uses your location to point you in the right direction — no routes, just a feeling."
        default:
            return "Location access is required for navigation."
        }
    }

    private var actionButton: some View {
        Group {
            switch authorizationStatus {
            case .denied, .restricted:
                Button {
                    openSettings()
                } label: {
                    Label("Open Settings", systemImage: "gear")
                        .bumperButton(.secondary)
                }

            case .notDetermined:
                Button {
                    onRequestPermission()
                } label: {
                    Text("Allow Location Access")
                        .bumperButton(.primary)
                }

            default:
                EmptyView()
            }
        }
    }

    // MARK: - Actions

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Preview

#Preview("Not Determined") {
    PermissionView(
        authorizationStatus: .notDetermined,
        onRequestPermission: {}
    )
}

#Preview("Denied") {
    PermissionView(
        authorizationStatus: .denied,
        onRequestPermission: {}
    )
}
