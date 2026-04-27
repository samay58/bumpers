import CoreLocation
import Foundation
import SwiftUI

struct SearchSuggestionRow: View {
    let suggestion: SearchSuggestion
    let isResolving: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                Image(systemName: "sparkle.magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 3) {
                    Text(suggestion.title)
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)

                    if !suggestion.subtitle.isEmpty {
                        Text(suggestion.subtitle)
                            .font(Theme.sectionHeaderFont)
                            .foregroundStyle(Theme.textTertiary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if isResolving {
                    ProgressView()
                        .tint(Theme.warm.inner)
                        .controlSize(.small)
                } else {
                    Image(systemName: "arrow.up.left")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .rowPressable()
        .disabled(isResolving)
    }
}

struct SearchResultRow: View {
    let result: SearchResult
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.warm.inner)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 3) {
                    Text(result.title)
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)

                    if !result.subtitle.isEmpty {
                        Text(result.subtitle)
                            .font(Theme.sectionHeaderFont)
                            .foregroundStyle(Theme.textTertiary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if let distance = result.distanceMeters {
                    Text(formatDistance(distance))
                        .font(Theme.labelFont)
                        .foregroundStyle(Theme.textTertiary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .rowPressable()
    }

    private func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance < 1_000 {
            return "\(Int(distance))m"
        }
        return String(format: "%.1fkm", distance / 1_000)
    }
}

struct RecentDestinationRow: View {
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
