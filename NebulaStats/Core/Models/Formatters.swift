import Foundation

/// Shared formatting for the whole app, so every screen renders
/// bytes, percentages and rates the same way.
enum Format {

    /// "12.4 GB" — storage and memory sizes.
    static func bytes(_ value: UInt64) -> String {
        bytes(Int64(value))
    }

    static func bytes(_ value: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: value, countStyle: .memory)
    }

    /// "87%" from a 0...1 fraction.
    static func percent(_ fraction: Double) -> String {
        "\(Int((fraction * 100).rounded()))%"
    }

    /// "24.6 MB/s" — live throughput from bytes per second.
    static func byteRate(_ bytesPerSecond: Double) -> String {
        guard bytesPerSecond >= 1 else { return "0 KB/s" }
        let formatted = ByteCountFormatter.string(
            fromByteCount: Int64(bytesPerSecond), countStyle: .decimal
        )
        return "\(formatted)/s"
    }

    /// "142 Mbps" or "8.5 Mbps" — speed test results.
    static func megabits(_ mbps: Double) -> String {
        mbps >= 100
            ? "\(Int(mbps.rounded())) Mbps"
            : String(format: "%.1f Mbps", mbps)
    }

    /// "3d 14h 22m" — time since boot.
    static func uptime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let days = total / 86400
        let hours = (total % 86400) / 3600
        let minutes = (total % 3600) / 60
        if days > 0 { return "\(days)d \(hours)h \(minutes)m" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}
