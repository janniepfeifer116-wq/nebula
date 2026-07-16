import SwiftUI

/// The standard card recipe: glassy fill, 20pt radius, a 1px accent-tinted
/// border, and (for hero cards) a soft outer glow.
struct GlassCard: ViewModifier {
    var borderColor: Color = .white.opacity(0.10)
    var fill: Color = Theme.card
    var glow: Color? = nil
    var glowRadius: CGFloat = 24
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(fill)
                    .background(.ultraThinMaterial.opacity(0.5),
                                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1)
            )
            .shadow(color: glow ?? .clear, radius: glow == nil ? 0 : glowRadius / 2)
    }
}

extension View {
    /// Standard card with a themed border, e.g. `.glassCard(border: Theme.violet.opacity(0.2))`.
    func glassCard(
        border: Color = .white.opacity(0.10),
        fill: Color = Theme.card,
        glow: Color? = nil,
        glowRadius: CGFloat = 24,
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 16
    ) -> some View {
        modifier(GlassCard(
            borderColor: border, fill: fill, glow: glow,
            glowRadius: glowRadius, cornerRadius: cornerRadius, padding: padding
        ))
    }
}

/// Status pill — "CHARGING", "LOW POWER", "OFFLINE"...
struct StatusPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text.uppercased())
            .font(.sans(9, .bold))
            .kerning(1.5)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(0.16)))
            .overlay(Capsule().strokeBorder(color.opacity(0.45), lineWidth: 1))
    }
}

// MARK: - Button styles

/// Violet→magenta gradient CTA with a resting glow.
struct PrimaryButtonStyle: ButtonStyle {
    var small = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.sans(small ? 12 : 15, .semibold))
            .foregroundStyle(.white)
            .padding(.vertical, small ? 9 : 15)
            .padding(.horizontal, small ? 16 : 20)
            .frame(maxWidth: small ? nil : .infinity)
            .background(
                RoundedRectangle(cornerRadius: small ? 12 : 14, style: .continuous)
                    .fill(Theme.buttonGradient)
            )
            .shadow(color: Theme.violetCTA.opacity(0.65), radius: small ? 9 : 12)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

/// Quiet glass-outline button.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.sans(14, .semibold))
            .foregroundStyle(Theme.textBody)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(.white.opacity(0.18), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

/// Tinted outline button (cyan by default; pass `Theme.critical` for destructive).
struct TintedButtonStyle: ButtonStyle {
    var tint: Color = Theme.cyan
    var labelColor: Color = Theme.cyanBright
    var small = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.sans(small ? 12 : 13, .semibold))
            .foregroundStyle(labelColor)
            .padding(.vertical, small ? 8 : 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: small ? nil : .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tint.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(tint.opacity(0.35), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}
