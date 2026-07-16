import SwiftUI

/// Glowing line chart for 60-second histories. Small "sparkline" uses in
/// cards omit the gridlines and area fill; large charts turn both on.
///
/// Values are normalized against `maxValue` (or the series' own peak when
/// nil, which suits throughput charts whose scale is unknowable up front).
struct SparklineChart: View {
    let values: [Double]
    var maxValue: Double? = 1.0
    var color: Color = Theme.violet
    var lineWidth: CGFloat = 1.5
    var showsGridlines = false
    var showsAreaFill = false
    /// A second series drawn thinner behind the first (e.g. upload under download).
    var secondaryValues: [Double]? = nil
    var secondaryColor: Color = Theme.cyanBright

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let scale = effectiveMax

            ZStack {
                if showsGridlines {
                    ForEach([0.25, 0.5, 0.75], id: \.self) { fraction in
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: size.height * fraction))
                            path.addLine(to: CGPoint(x: size.width, y: size.height * fraction))
                        }
                        .stroke(.white.opacity(0.05), lineWidth: 1)
                    }
                }

                if let secondaryValues, secondaryValues.count > 1 {
                    linePath(secondaryValues, in: size, scale: scale)
                        .stroke(secondaryColor, style: StrokeStyle(lineWidth: 1.2, lineJoin: .round))
                        .shadow(color: secondaryColor.opacity(0.8), radius: 2.5)
                }

                if values.count > 1 {
                    if showsAreaFill {
                        areaPath(values, in: size, scale: scale)
                            .fill(LinearGradient(
                                colors: [color.opacity(0.35), color.opacity(0)],
                                startPoint: .top, endPoint: .bottom
                            ))
                    }
                    linePath(values, in: size, scale: scale)
                        .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineJoin: .round))
                        .shadow(color: color.opacity(0.9), radius: 3)

                    if let lastPoint = point(at: values.count - 1, of: values, in: size, scale: scale) {
                        Circle()
                            .fill(color)
                            .frame(width: 5, height: 5)
                            .position(lastPoint)
                            .shadow(color: color, radius: 4)
                    }
                }
            }
        }
    }

    private var effectiveMax: Double {
        if let maxValue { return maxValue }
        let peak = max(values.max() ?? 0, secondaryValues?.max() ?? 0)
        return peak > 0 ? peak : 1
    }

    private func point(at index: Int, of series: [Double], in size: CGSize, scale: Double) -> CGPoint? {
        guard series.count > 1 else { return nil }
        let x = size.width * CGFloat(index) / CGFloat(series.count - 1)
        let normalized = min(series[index] / scale, 1)
        let y = size.height * (1 - CGFloat(normalized))
        return CGPoint(x: x, y: y)
    }

    private func linePath(_ series: [Double], in size: CGSize, scale: Double) -> Path {
        Path { path in
            for index in series.indices {
                guard let p = point(at: index, of: series, in: size, scale: scale) else { continue }
                index == 0 ? path.move(to: p) : path.addLine(to: p)
            }
        }
    }

    private func areaPath(_ series: [Double], in size: CGSize, scale: Double) -> Path {
        var path = linePath(series, in: size, scale: scale)
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.addLine(to: CGPoint(x: 0, y: size.height))
        path.closeSubpath()
        return path
    }
}
