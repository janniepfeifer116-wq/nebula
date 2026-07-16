import SwiftUI

/// The semicircular speed-test gauge: a 180° arc filled left-to-right with
/// the cyan→violet gradient, a needle from the pivot, and scale labels.
/// The scale is non-linear (square-root) so both slow and gigabit
/// connections travel a satisfying share of the arc.
struct SpeedGauge: View {
    /// Current reading in Mbps.
    let mbps: Double
    var maxScale: Double = 1000

    private var sweepFraction: Double {
        guard mbps > 0 else { return 0 }
        return min(sqrt(mbps / maxScale), 1)
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let radius = width / 2 - 10
            let center = CGPoint(x: width / 2, y: radius + 10)

            ZStack {
                arc(from: 0, to: 1, center: center, radius: radius)
                    .stroke(.white.opacity(0.07), style: StrokeStyle(lineWidth: 13, lineCap: .round))

                arc(from: 0, to: sweepFraction, center: center, radius: radius)
                    .stroke(Theme.speedGaugeGradient, style: StrokeStyle(lineWidth: 13, lineCap: .round))
                    .shadow(color: Theme.cyan.opacity(0.9), radius: 7)

                tipDot(center: center, radius: radius)
                needle(center: center, radius: radius)

                Circle()
                    .fill(Theme.textPrimary)
                    .frame(width: 12, height: 12)
                    .position(center)

                scaleLabel("0", at: angle(for: 0), center: center, radius: radius + 16)
                scaleLabel("\(Int(maxScale) / 2)", at: angle(for: 0.5), center: center, radius: radius + 16)
                scaleLabel("\(Int(maxScale))", at: angle(for: 1), center: center, radius: radius + 16)
            }
            // Updates arrive at 10 Hz; a short curve keeps the needle gliding
            // instead of stepping.
            .animation(.easeOut(duration: 0.15), value: sweepFraction)
        }
        .aspectRatio(300 / 185, contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel("Speed gauge")
        .accessibilityValue("\(Int(mbps)) megabits per second")
    }

    /// 0 → 180° (left), 1 → 360° (right); SwiftUI angles measure clockwise from 3 o'clock.
    private func angle(for fraction: Double) -> Angle {
        .degrees(180 + fraction * 180)
    }

    private func arc(from start: Double, to end: Double, center: CGPoint, radius: CGFloat) -> Path {
        Path { path in
            path.addArc(center: center, radius: radius,
                        startAngle: angle(for: start), endAngle: angle(for: end),
                        clockwise: false)
        }
    }

    private func needle(center: CGPoint, radius: CGFloat) -> some View {
        let tip = point(on: angle(for: sweepFraction), center: center, radius: radius - 16)
        return Path { path in
            path.move(to: center)
            path.addLine(to: tip)
        }
        .stroke(Theme.textPrimary.opacity(0.85), lineWidth: 2)
    }

    private func tipDot(center: CGPoint, radius: CGFloat) -> some View {
        Circle()
            .fill(Theme.cyanIce)
            .frame(width: 14, height: 14)
            .position(point(on: angle(for: sweepFraction), center: center, radius: radius))
            .shadow(color: Theme.cyan, radius: 6)
    }

    private func scaleLabel(_ text: String, at angle: Angle, center: CGPoint, radius: CGFloat) -> some View {
        Text(text)
            .font(.mono(9))
            .foregroundStyle(Theme.textDisabled)
            .position(point(on: angle, center: center, radius: radius))
    }

    private func point(on angle: Angle, center: CGPoint, radius: CGFloat) -> CGPoint {
        CGPoint(
            x: center.x + radius * CGFloat(Darwin.cos(angle.radians)),
            y: center.y + radius * CGFloat(Darwin.sin(angle.radians))
        )
    }
}
