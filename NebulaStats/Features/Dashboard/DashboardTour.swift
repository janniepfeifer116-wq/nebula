import SwiftUI

/// First-launch walkthrough of the dashboard: a dimmed overlay with a
/// "spotlight" cut out around one card at a time and a plain-language
/// explanation bubble. Skippable at any moment; replayable from Settings.

/// The dashboard elements the tour can point at.
enum TourTarget: Int, Hashable {
    case cpu, memory, storage, battery, network, display, score
}

/// Collects each card's on-screen position via SwiftUI anchors.
struct TourAnchorKey: PreferenceKey {
    static var defaultValue: [TourTarget: Anchor<CGRect>] = [:]
    static func reduce(
        value: inout [TourTarget: Anchor<CGRect>],
        nextValue: () -> [TourTarget: Anchor<CGRect>]
    ) {
        value.merge(nextValue()) { $1 }
    }
}

extension View {
    /// Marks a view as a tour stop so the overlay can spotlight it.
    func tourTarget(_ target: TourTarget) -> some View {
        anchorPreference(key: TourAnchorKey.self, value: .bounds) { [target: $0] }
    }
}

enum DashboardTour {
    struct Step {
        /// Card to spotlight; nil dims nothing and centers the bubble.
        let target: TourTarget?
        let title: String
        let text: String
    }

    /// Written for people who aren't tech geeks — no jargon.
    static let steps: [Step] = [
        .init(target: .cpu, title: "Processor",
              text: "This ring shows how hard your phone's brain is working right now. Higher percentage means busier."),
        .init(target: .memory, title: "Memory",
              text: "Your phone's short-term workspace. Looking almost full is normal — iOS tidies it up automatically."),
        .init(target: .storage, title: "Storage",
              text: "The space your photos, apps and files take up — and how much is still free."),
        .init(target: .battery, title: "Battery",
              text: "Your battery's charge level and temperature status, updated live."),
        .init(target: .network, title: "Network",
              text: "Your internet activity, live: ▼ is data coming in, ▲ is data going out."),
        .init(target: .display, title: "Display",
              text: "How smoothly your screen is drawing, in frames per second. More is smoother."),
        .init(target: .score, title: "Nebula Score",
              text: "A quick, safe speed test for your phone's chip — a few seconds of math, nothing on your phone is changed."),
        .init(target: nil, title: "That's it!",
              text: "The tabs below open each area in detail. Everything is measured on your device — nothing ever leaves it."),
    ]
}

struct TourOverlay: View {
    let stepIndex: Int
    let anchors: [TourTarget: Anchor<CGRect>]
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let step = DashboardTour.steps[stepIndex]
            let spotlight: CGRect? = step.target
                .flatMap { anchors[$0] }
                .map { proxy[$0].insetBy(dx: -6, dy: -6) }

            ZStack {
                // The dim layer ignores the safe area, so its coordinate
                // space starts at the physical screen edge — shift the hole
                // down/right by the insets to keep it glued to the card.
                SpotlightDim(hole: spotlight?.offsetBy(
                    dx: proxy.safeAreaInsets.leading,
                    dy: proxy.safeAreaInsets.top
                ))
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {} // swallow taps: only Skip/Next/Done control the tour

                if let spotlight {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Theme.violetBright.opacity(0.8), lineWidth: 1.5)
                        .shadow(color: Theme.violet.opacity(0.8), radius: 8)
                        .frame(width: spotlight.width, height: spotlight.height)
                        .position(x: spotlight.midX, y: spotlight.midY)
                        .allowsHitTesting(false)
                }

                bubble(for: step, near: spotlight, in: proxy.size)
            }
        }
        .transition(.opacity)
    }

    // MARK: - Bubble

    private func bubble(for step: DashboardTour.Step, near spotlight: CGRect?, in size: CGSize) -> some View {
        let bubbleHalfHeight: CGFloat = 92
        let y: CGFloat
        if let spotlight {
            // Below the card when it sits in the top half, above it otherwise.
            y = spotlight.midY < size.height / 2
                ? min(spotlight.maxY + bubbleHalfHeight + 12, size.height - bubbleHalfHeight - 16)
                : max(spotlight.minY - bubbleHalfHeight - 12, bubbleHalfHeight + 16)
        } else {
            y = size.height / 2
        }

        return VStack(alignment: .leading, spacing: 10) {
            Text(step.title)
                .font(.sans(16, .bold))
                .foregroundStyle(Theme.textPrimary)
            Text(step.text)
                .font(.sans(13))
                .foregroundStyle(Theme.textBody)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Button("Skip", action: onSkip)
                    .font(.sans(13))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                stepDots
                Spacer()
                Button(isLastStep ? "Done" : "Next", action: onNext)
                    .buttonStyle(PrimaryButtonStyle(small: true))
            }
        }
        .glassCard(
            border: Theme.violet.opacity(0.35),
            fill: Color(hex: 0x17172E, opacity: 0.94),
            glow: Theme.violetCTA.opacity(0.3), glowRadius: 30,
            padding: 18
        )
        .frame(width: min(size.width - 40, 420))
        .position(x: size.width / 2, y: y)
    }

    private var isLastStep: Bool {
        stepIndex == DashboardTour.steps.count - 1
    }

    private var stepDots: some View {
        HStack(spacing: 5) {
            ForEach(DashboardTour.steps.indices, id: \.self) { index in
                Circle()
                    .fill(index == stepIndex ? Theme.violetBright : Color.white.opacity(0.2))
                    .frame(width: 5, height: 5)
            }
        }
    }
}

/// The dim layer with a rounded hole cut out over the spotlit card.
private struct SpotlightDim: View {
    let hole: CGRect?

    var body: some View {
        SpotlightShape(hole: hole)
            .fill(Color.black.opacity(0.68), style: FillStyle(eoFill: true))
    }
}

private struct SpotlightShape: Shape {
    let hole: CGRect?

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)
        if let hole {
            path.addRoundedRect(in: hole, cornerSize: CGSize(width: 24, height: 24))
        }
        return path
    }
}
