import SwiftUI

/// Settings bottom sheet: refresh cadence, reduce motion, and the
/// privacy/about box.
struct SettingsView: View {
    @Environment(StatsHub.self) private var hub
    @Environment(\.dismiss) private var dismiss
    @AppStorage("reduceMotion") private var reduceMotion = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Settings")
                    .font(.sans(18, .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button("Done") { dismiss() }
                    .font(.sans(13, .semibold))
                    .foregroundStyle(Theme.cyanBright)
            }
            .padding(.top, 6)

            VStack(alignment: .leading, spacing: 8) {
                MicroLabel(text: "Refresh rate")
                refreshRatePicker
            }

            togglesGroup
            replayTourRow
            if !ReviewPromptCoordinator.appStoreID.isEmpty {
                rateAppRow
            }
            aboutBox

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .presentationDetents([.medium, .large])
        .presentationBackground {
            Color(hex: 0x121226, opacity: 0.92)
                .background(.ultraThinMaterial)
        }
        .presentationCornerRadius(28)
        .presentationDragIndicator(.visible)
    }

    // MARK: - Refresh rate

    private var refreshRatePicker: some View {
        HStack(spacing: 4) {
            ForEach([1.0, 2.0, 5.0], id: \.self) { interval in
                let isSelected = hub.refreshInterval == interval
                Button {
                    hub.refreshInterval = interval
                } label: {
                    Text("\(Int(interval)) s")
                        .font(.sans(12, isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? Theme.base : Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(isSelected
                                      ? AnyShapeStyle(Theme.gradientSegmentSelected)
                                      : AnyShapeStyle(Color.clear))
                        )
                }
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white.opacity(0.06))
        )
    }

    // MARK: - Toggles

    private var togglesGroup: some View {
        HStack {
            Text("Reduce motion")
                .font(.sans(13))
                .foregroundStyle(Theme.textBody)
            Spacer()
            Toggle("", isOn: $reduceMotion)
                .labelsHidden()
                .tint(Theme.aurora.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassCard(cornerRadius: 16, padding: 0)
    }

    private var replayTourRow: some View {
        Button {
            UserDefaults.standard.set(false, forKey: "hasSeenDashboardTour")
            dismiss()
        } label: {
            HStack {
                Text("Replay dashboard tour")
                    .font(.sans(13))
                    .foregroundStyle(Theme.textBody)
                Spacer()
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.cyanBright)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .glassCard(cornerRadius: 16, padding: 0)
    }

    private var rateAppRow: some View {
        Button {
            let url = "https://apps.apple.com/app/id\(ReviewPromptCoordinator.appStoreID)?action=write-review"
            if let reviewURL = URL(string: url) {
                UIApplication.shared.open(reviewURL)
            }
        } label: {
            HStack {
                Text("Rate Nebula Stats")
                    .font(.sans(13))
                    .foregroundStyle(Theme.textBody)
                Spacer()
                Image(systemName: "star")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.warning)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .glassCard(cornerRadius: 16, padding: 0)
    }

    // MARK: - About

    private var aboutBox: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Nebula Stats \(appVersion)")
                .font(.sans(12, .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("All measurements happen on-device. No analytics, no tracking, no data leaves your phone. Speed tests exchange traffic only with the test server.")
                .font(.sans(11))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(
            border: .white.opacity(0.08),
            fill: Theme.cardFaint,
            cornerRadius: 16, padding: 14
        )
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
}

extension Theme {
    static let gradientSegmentSelected = LinearGradient(
        colors: [cyanBright, violet], startPoint: .topLeading, endPoint: .bottomTrailing
    )
}
