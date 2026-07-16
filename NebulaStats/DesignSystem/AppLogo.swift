import SwiftUI

/// The orbit mark: a broken gradient ring, a glowing core, and a satellite
/// dot at the upper right. Used on onboarding and the iPad sidebar.
struct AppLogo: View {
    var size: CGFloat = 120

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(Theme.logoGradient, style: StrokeStyle(lineWidth: size * 0.075, lineCap: .round))
                .rotationEffect(.degrees(120))
                .frame(width: size * 0.73, height: size * 0.73)
                .shadow(color: Theme.violetCTA.opacity(0.7), radius: 6)

            Circle()
                .fill(Theme.logoGradient)
                .frame(width: size * 0.27, height: size * 0.27)
                .shadow(color: Theme.cyan.opacity(0.8), radius: 5)

            Circle()
                .fill(Theme.violetBright)
                .frame(width: size * 0.1, height: size * 0.1)
                .offset(x: size * 0.31, y: -size * 0.31)
                .shadow(color: Theme.violet, radius: 3)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
