import SwiftUI

/// Slim glowing progress bar for memory usage. Swaps to the amber warning
/// gradient when the fraction crosses the pressure threshold.
struct MemoryBar: View {
    /// 0...1
    let fraction: Double
    var height: CGFloat = 6

    private var isUnderPressure: Bool { fraction >= 0.85 }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.07))
                Capsule()
                    .fill(isUnderPressure ? Theme.memoryWarningGradient : Theme.memoryFillGradient)
                    .frame(width: max(geometry.size.width * fraction, height))
                    .shadow(color: (isUnderPressure ? Theme.warning : Theme.cyan).opacity(0.6), radius: 6)
                    .animation(.easeOut(duration: 0.5), value: fraction)
            }
        }
        .frame(height: height)
    }
}

/// The Performance tab's three-segment memory bar (active / wired / compressed).
struct SegmentedMemoryBar: View {
    let memory: MemorySampler.Snapshot

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let total = Double(memory.totalBytes)
            HStack(spacing: 0) {
                segment(Theme.cyan, width * fraction(memory.activeBytes, of: total))
                segment(Theme.cyanBright, width * fraction(memory.wiredBytes, of: total))
                segment(Theme.cyanBright.opacity(0.35), width * fraction(memory.compressedBytes, of: total))
                Spacer(minLength: 0)
            }
            .background(Color.white.opacity(0.07))
            .clipShape(Capsule())
        }
        .frame(height: 8)
    }

    private func fraction(_ bytes: UInt64, of total: Double) -> CGFloat {
        total > 0 ? CGFloat(Double(bytes) / total) : 0
    }

    private func segment(_ color: Color, _ width: CGFloat) -> some View {
        Rectangle().fill(color).frame(width: max(width, 0))
    }
}
