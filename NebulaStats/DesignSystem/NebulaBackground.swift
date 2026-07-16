import SwiftUI

/// The app-wide backdrop: deep-space base color, three soft radial nebula
/// blooms, and a sparse static starfield. Identical on every screen; the
/// speed-test modal swaps in its own bloom pair via `style: .speedTest`.
struct NebulaBackground: View {
    enum Style { case standard, speedTest }
    var style: Style = .standard

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ZStack {
                Theme.base

                switch style {
                case .standard:
                    bloom(Theme.nebulaViolet, center: UnitPoint(x: 0.85, y: -0.1), radius: 1.1 * size.width)
                    bloom(Theme.nebulaBlue, center: UnitPoint(x: -0.15, y: 0.35), radius: 0.95 * size.width)
                    bloom(Theme.nebulaIndigo, center: UnitPoint(x: 0.5, y: 1.15), radius: 1.2 * size.width)
                case .speedTest:
                    bloom(Theme.nebulaSpeedBlue, center: UnitPoint(x: 0.5, y: -0.2), radius: 1.2 * size.width)
                    bloom(Theme.nebulaSpeedViolet, center: UnitPoint(x: 1.0, y: 1.0), radius: 1.1 * size.width)
                }

                Starfield(size: size)
            }
        }
        .ignoresSafeArea()
    }

    private func bloom(_ color: Color, center: UnitPoint, radius: CGFloat) -> some View {
        RadialGradient(
            colors: [color, color.opacity(0)],
            center: center, startRadius: 0, endRadius: radius
        )
    }
}

/// Static decoration dots. Positions are fixed fractions of the screen so
/// the field looks hand-placed (as in the design), not random per launch.
private struct Starfield: View {
    let size: CGSize

    // (x%, y%, dot size, opacity, isBlueTinted)
    private static let stars: [(CGFloat, CGFloat, CGFloat, Double, Bool)] = [
        (0.20, 0.15, 1.0, 0.45, false),
        (0.75, 0.10, 1.5, 0.60, false),
        (0.60, 0.40, 1.0, 0.30, true),
        (0.15, 0.62, 1.0, 0.50, false),
        (0.85, 0.78, 1.5, 0.40, true),
        (0.40, 0.88, 1.0, 0.35, false),
        (0.92, 0.35, 1.0, 0.55, false),
        (0.30, 0.30, 1.0, 0.30, true),
    ]

    var body: some View {
        ForEach(Array(Self.stars.enumerated()), id: \.offset) { _, star in
            Circle()
                .fill(star.4 ? Color(hex: 0xBED2FF, opacity: star.3) : .white.opacity(star.3))
                .frame(width: star.2 * 2, height: star.2 * 2)
                .position(x: star.0 * size.width, y: star.1 * size.height)
        }
    }
}
