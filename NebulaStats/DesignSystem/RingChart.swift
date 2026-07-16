import SwiftUI

/// Segmented storage donut: a used-space arc over a faint track, with the
/// used percentage in the middle. (The design's two-segment split into
/// apps/system isn't knowable from public APIs, so we draw one violet
/// used-segment; free space shows through as the track.)
struct RingChart: View {
    /// 0...1 fraction of the ring to fill.
    let fraction: Double
    var diameter: CGFloat = 76
    var lineWidth: CGFloat = 9
    var color: Color = Theme.violet
    var centerText: String? = nil

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.ringTrack, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: fraction)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.85), radius: 4)
                .animation(.easeOut(duration: 0.5), value: fraction)

            if let centerText {
                Text(centerText)
                    .font(.mono(15, .semibold))
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .frame(width: diameter, height: diameter)
    }
}

/// Legend row under a ring: "■ Apps & data   115 GB".
struct LegendRow: View {
    let color: Color
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text("■")
                .font(.mono(9))
                .foregroundStyle(color)
            Text(label)
                .font(.sans(11))
                .foregroundStyle(Theme.textBody)
            Spacer()
            Text(value)
                .font(.mono(11))
                .foregroundStyle(Theme.textPrimary)
        }
    }
}

/// One per-core load row: "P1 [▬▬▬▬░░░░] 64".
struct CoreBarRow: View {
    let label: String
    /// 0...1
    let load: Double
    /// Violet for performance cores, cyan for efficiency cores.
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.mono(8))
                .foregroundStyle(Theme.textDisabled)
                .frame(width: 16, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.barTrack)
                    Capsule()
                        .fill(color)
                        .frame(width: max(geometry.size.width * load, 4))
                        .shadow(color: color.opacity(0.85), radius: 4)
                        .animation(.easeOut(duration: 0.5), value: load)
                }
            }
            .frame(height: 4)

            Text("\(Int((load * 100).rounded()))")
                .font(.mono(8))
                .foregroundStyle(Theme.textMicro)
                .frame(width: 18, alignment: .trailing)
        }
    }
}
