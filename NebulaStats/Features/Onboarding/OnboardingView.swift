import SwiftUI

/// Single-screen welcome: logo, tagline, three feature bullets, one button.
/// No permission prompts here — the app asks for nothing at launch.
struct OnboardingView: View {
    let onFinish: () -> Void

    var body: some View {
        ZStack {
            NebulaBackground()

            VStack(spacing: 0) {
                AppLogo(size: 120)
                    .padding(.top, 90)

                Text("Nebula Stats")
                    .font(.sans(30, .bold))
                    .kerning(0.5)
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.top, 22)

                Text("MISSION CONTROL FOR YOUR DEVICE")
                    .font(.sans(11, .semibold))
                    .kerning(3)
                    .foregroundStyle(Theme.textMicro)
                    .padding(.top, 6)

                VStack(spacing: 20) {
                    featureRow(
                        icon: "chart.xyaxis.line", tint: Theme.violet,
                        title: "Live telemetry",
                        description: "CPU, memory, battery and display — refreshed every second."
                    )
                    featureRow(
                        icon: "wifi", tint: Theme.cyan,
                        title: "Network insight",
                        description: "Throughput, addresses and a built-in speed test."
                    )
                    featureRow(
                        icon: "shield", tint: Theme.aurora,
                        title: "Private by design",
                        description: "Everything is measured on-device. Nothing leaves it."
                    )
                }
                .padding(.top, 48)

                Spacer()

                Button("Enter the dashboard", action: onFinish)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 32)
        }
    }

    private func featureRow(icon: String, tint: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(tint)
                .shadow(color: tint.opacity(0.7), radius: 3)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.sans(14, .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(description)
                    .font(.sans(12))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
        }
    }
}
