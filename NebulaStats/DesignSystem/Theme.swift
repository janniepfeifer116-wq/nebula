import SwiftUI

// The design tokens from design/DESIGN-SPEC.md, kept 1:1 with the spec's
// names so a value in the mockup is easy to find here.

extension Color {
    /// Color from a hex literal, e.g. `Color(hex: 0x0B0B1E)`.
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

enum Theme {

    // MARK: Surfaces

    static let base = Color(hex: 0x0B0B1E)
    static let card = Color.white.opacity(0.04)
    static let cardHero = Color(hex: 0x8C78FF, opacity: 0.09)
    static let cardFaint = Color.white.opacity(0.03)
    static let ringTrack = Color.white.opacity(0.08)
    static let barTrack = Color.white.opacity(0.06)
    static let divider = Color.white.opacity(0.06)

    // MARK: Nebula bloom colors

    // Saturated ~50% past the original spec values for a punchier look.
    static let nebulaViolet = Color(hex: 0x39207E)
    static let nebulaBlue = Color(hex: 0x14386B)
    static let nebulaIndigo = Color(hex: 0x241760)
    static let nebulaSpeedBlue = Color(hex: 0x144385)
    static let nebulaSpeedViolet = Color(hex: 0x301B78)

    // MARK: Text

    static let textPrimary = Color(hex: 0xF2F2FA)
    static let textHero = Color(hex: 0xF4FAFF)
    static let textBody = Color(hex: 0xC9CBE4)
    static let textSecondary = Color(hex: 0x8F8FB8)
    static let textMicro = Color(hex: 0x9FA6D8)
    static let textMuted = Color(hex: 0x7C86B8)
    static let textDisabled = Color(hex: 0x5E648F)
    static let tabInactive = Color(hex: 0x6B7099)

    // MARK: Accents & states

    // Accents boosted ~50% in chroma versus the original spec.
    static let violet = Color(hex: 0x9B6BFF)
    static let violetBright = Color(hex: 0xC7A6FF)
    static let violetCTA = Color(hex: 0x8A3FFF)
    static let magentaCTA = Color(hex: 0xE32BFF)
    static let cyan = Color(hex: 0x1FC3FF)
    static let cyanBright = Color(hex: 0x66D9FF)
    static let cyanDeep = Color(hex: 0x00E5FF)
    static let cyanIce = Color(hex: 0xB0EBFF)
    static let aurora = Color(hex: 0x2EF08A)
    static let magenta = Color(hex: 0xFF57C0)
    static let warning = Color(hex: 0xFFB308)
    static let critical = Color(hex: 0xFF4D71)

    // MARK: Gradients

    static let gaugeGradient = LinearGradient(
        colors: [cyan, violet], startPoint: .bottomLeading, endPoint: .topTrailing
    )
    static let gaugeWarningGradient = LinearGradient(
        colors: [warning, magenta], startPoint: .bottomLeading, endPoint: .topTrailing
    )
    static let buttonGradient = LinearGradient(
        colors: [violetCTA, magentaCTA], startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let memoryFillGradient = LinearGradient(
        colors: [cyan, cyanBright], startPoint: .leading, endPoint: .trailing
    )
    static let memoryWarningGradient = LinearGradient(
        colors: [warning, magenta], startPoint: .leading, endPoint: .trailing
    )
    static let speedGaugeGradient = LinearGradient(
        stops: [
            .init(color: cyanDeep, location: 0),
            .init(color: cyan, location: 0.6),
            .init(color: violet, location: 1),
        ],
        startPoint: .leading, endPoint: .trailing
    )
    static let logoGradient = LinearGradient(
        stops: [
            .init(color: cyanDeep, location: 0),
            .init(color: cyan, location: 0.5),
            .init(color: violet, location: 1),
        ],
        startPoint: .bottomLeading, endPoint: .topTrailing
    )
}

// MARK: - Type scale helpers

extension Font {
    /// SF Mono — used for every numeric readout, address and telemetry line.
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    /// SF Pro — regular UI text.
    static func sans(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
}

/// Tracked-out uppercase eyebrow, e.g. "CPU LOAD" above a card value.
struct MicroLabel: View {
    let text: String
    var color: Color = Theme.textMicro
    var size: CGFloat = 10

    var body: some View {
        Text(text.uppercased())
            .font(.sans(size, .semibold))
            .kerning(2.2)
            .foregroundStyle(color)
    }
}
