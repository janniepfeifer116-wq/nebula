import SwiftUI

/// Circular gauge with a glowing gradient arc, a value in the center and a
/// bright dot riding the arc's tip. The look shifts with load: gradient arc
/// when healthy, amber gradient past 70%, solid rose past 90%.
struct GaugeOrb: View {
    /// 0...1, or nil for the "no data" state.
    let value: Double?
    var caption: String? = nil
    var diameter: CGFloat = 118

    private enum Severity { case normal, warning, critical }

    private var severity: Severity {
        switch value ?? 0 {
        case ..<0.7: .normal
        case ..<0.9: .warning
        default: .critical
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Theme.ringTrack, lineWidth: 8)

                if let value {
                    arc(for: value)
                    if severity == .normal {
                        tipDot(for: value)
                    }
                }

                VStack(spacing: 2) {
                    Text(value.map { "\(Int(($0 * 100).rounded()))" } ?? "--")
                        .font(.mono(diameter * 0.24, .semibold))
                        .foregroundStyle(valueColor)
                        .contentTransition(.numericText())
                    Text("%")
                        .font(.sans(9, .semibold))
                        .kerning(2)
                        .foregroundStyle(unitColor)
                }
            }
            .frame(width: diameter, height: diameter)

            if let caption {
                MicroLabel(text: captionText(caption), color: captionColor, size: 8)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(caption ?? "Gauge")
        .accessibilityValue(value.map { "\(Int($0 * 100)) percent" } ?? "no data")
    }

    // MARK: - Pieces

    private func arc(for value: Double) -> some View {
        Circle()
            .trim(from: 0, to: value)
            .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
            .fill(arcStyle)
            .rotationEffect(.degrees(-90))
            .shadow(color: glowColor, radius: 4.5)
            .animation(.easeOut(duration: 0.5), value: value)
    }

    private func tipDot(for value: Double) -> some View {
        Circle()
            .fill(Theme.violetBright)
            .frame(width: 9, height: 9)
            .offset(y: -diameter / 2)
            .rotationEffect(.degrees(value * 360))
            .shadow(color: Theme.violet, radius: 4)
            .animation(.easeOut(duration: 0.5), value: value)
    }

    // MARK: - State styling

    private var arcStyle: AnyShapeStyle {
        switch severity {
        case .normal: AnyShapeStyle(Theme.gaugeGradient)
        case .warning: AnyShapeStyle(Theme.gaugeWarningGradient)
        case .critical: AnyShapeStyle(Theme.critical)
        }
    }

    private var glowColor: Color {
        switch severity {
        case .normal: Theme.violetCTA.opacity(0.7)
        case .warning: Theme.warning.opacity(0.7)
        case .critical: Theme.critical.opacity(0.8)
        }
    }

    private var valueColor: Color {
        value == nil ? Theme.textDisabled
            : severity == .critical ? Theme.critical : Theme.textPrimary
    }

    private var unitColor: Color {
        switch severity {
        case .normal: Theme.textSecondary
        case .warning: Theme.warning
        case .critical: Theme.critical
        }
    }

    private var captionColor: Color {
        if value == nil { return Theme.textDisabled }
        switch severity {
        case .normal: return Theme.textMicro
        case .warning: return Theme.warning
        case .critical: return Theme.critical
        }
    }

    private func captionText(_ base: String) -> String {
        if value == nil { return "NO DATA" }
        switch severity {
        case .normal: return base
        case .warning: return "⚠ HIGH LOAD"
        case .critical: return "✕ CRITICAL"
        }
    }
}
