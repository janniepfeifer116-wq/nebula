import SwiftUI

/// Connection status, Wi-Fi name (opt-in reveal), addresses, live
/// throughput, and the entry point to the speed test.
struct NetworkView: View {
    @Environment(StatsHub.self) private var hub
    @State private var showsSpeedTest = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                header
                addressList
                throughputCard
                speedTestRow
                if !hub.speedHistory.isEmpty {
                    historyCard
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 90)
        }
        .fullScreenCover(isPresented: $showsSpeedTest) {
            SpeedTestView()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi")
                .font(.system(size: 24))
                .foregroundStyle(Theme.cyan)
                .shadow(color: Theme.cyan.opacity(0.7), radius: 3)
            VStack(alignment: .leading, spacing: 2) {
                Text("Network")
                    .font(.sans(20, .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(connectionSubtitle)
                    .font(.mono(9))
                    .kerning(1)
                    .foregroundStyle(hub.networkPath.connection == .offline ? Theme.textDisabled : Theme.aurora)
            }
            Spacer()
        }
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    private var connectionSubtitle: String {
        let path = hub.networkPath
        if path.connection == .offline { return "OFFLINE" }
        var parts = [path.connection.rawValue.uppercased(), "CONNECTED"]
        if path.connection == .cellular, let radio = hub.radioTechnology {
            parts[0] = radio.uppercased()
        }
        return parts.joined(separator: " · ")
    }

    // MARK: - Addresses

    private var addressList: some View {
        var rows = hub.localAddresses.map { address in
            KeyValueList.Row(
                label: address.isIPv6 ? "IPv6 · \(address.interface)" : "IPv4 · \(address.interface)",
                value: address.ip,
                isCopyable: true
            )
        }
        if let publicIP = hub.publicIP {
            rows.append(KeyValueList.Row(label: "Public IP", value: publicIP, isCopyable: true))
        }
        return VStack(spacing: 12) {
            if !rows.isEmpty {
                KeyValueList(header: "Addresses", rows: rows)
            }
            if hub.publicIP == nil {
                Button(hub.isFetchingPublicIP ? "Fetching…" : "Fetch public IP") {
                    Task { await hub.fetchPublicIP() }
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(hub.isFetchingPublicIP)
            }
        }
    }

    // MARK: - Throughput

    private var throughputCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                MicroLabel(text: "Throughput", size: 9)
                Spacer()
                Text("▼ \(Format.byteRate(hub.downloadBytesPerSecond))")
                    .font(.mono(12))
                    .foregroundStyle(Theme.aurora)
                Text("▲ \(Format.byteRate(hub.uploadBytesPerSecond))")
                    .font(.mono(12))
                    .foregroundStyle(Theme.cyanBright)
            }

            SparklineChart(
                values: hub.downloadHistory.values,
                maxValue: nil,
                color: Theme.aurora,
                showsGridlines: true,
                showsAreaFill: true,
                secondaryValues: hub.uploadHistory.values
            )
            .frame(height: 40)

            if let counts = hub.byteCounts {
                HStack {
                    Text("SINCE BOOT ▼ \(Format.bytes(counts.totalReceived)) · ▲ \(Format.bytes(counts.totalSent))")
                    Spacer()
                    Text("60 S")
                }
                .font(.mono(9))
                .foregroundStyle(Theme.textMuted)
            }
        }
        .glassCard(border: Theme.aurora.opacity(0.2))
    }

    // MARK: - Speed test entry

    private var speedTestRow: some View {
        // Non-nil while a cooldown (server rate limit or our pacing) is active.
        let cooldown: (minutes: Int, isServerLimit: Bool)? = hub.speedTest.cooldownUntil.flatMap { until in
            let remaining = until.timeIntervalSinceNow
            guard remaining > 0 else { return nil }
            return (max(1, Int(remaining / 60) + 1),
                    hub.speedTest.cooldownReason == .serverLimit)
        }

        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Speed test")
                    .font(.sans(13, .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(cooldown.map {
                    $0.isServerLimit
                        ? "Server is limiting this network · lifts in ~\($0.minutes) min"
                        : "Next run in ~\($0.minutes) min"
                } ?? lastRunSummary)
                    .font(.sans(10))
                    .foregroundStyle(cooldown == nil ? Theme.textSecondary
                                     : cooldown!.isServerLimit ? Theme.warning : Theme.textMicro)
            }
            Spacer()
            Button("Run test") { showsSpeedTest = true }
                .buttonStyle(PrimaryButtonStyle(small: true))
                .disabled(cooldown != nil)
                .opacity(cooldown == nil ? 1 : 0.4)
        }
        .glassCard(
            border: Theme.violet.opacity(0.28),
            fill: Theme.cardHero,
            glow: Theme.violetCTA.opacity(0.24), glowRadius: 24
        )
    }

    private var lastRunSummary: String {
        if let latest = hub.speedHistory.first {
            return "Last run · \(Format.megabits(latest.downloadMbps)) down"
        }
        return "Latency, download and upload"
    }

    // MARK: - History (last 7 days)

    private var historyCard: some View {
        let records = hub.speedHistory
        let peak = records.map(\.downloadMbps).max() ?? 1

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                MicroLabel(text: "History · last 7 days", size: 9)
                Spacer()
                Text("\(records.count) RUNS")
                    .font(.mono(9))
                    .foregroundStyle(Theme.textMuted)
            }

            // Download bars, oldest → newest left to right.
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(records.reversed()) { record in
                    Capsule()
                        .fill(Theme.gaugeGradient)
                        .frame(width: 8, height: max(6, 44 * record.downloadMbps / peak))
                        .shadow(color: Theme.cyan.opacity(0.5), radius: 2)
                }
            }
            .frame(height: 44, alignment: .bottom)

            VStack(spacing: 0) {
                ForEach(records.prefix(5)) { record in
                    HStack {
                        Text(record.date.formatted(.dateTime.weekday(.abbreviated).hour().minute()))
                            .font(.mono(10))
                            .foregroundStyle(Theme.textMuted)
                        Text(record.connection.uppercased())
                            .font(.mono(9))
                            .foregroundStyle(Theme.textMicro)
                        Spacer()
                        Text("▼ \(Format.megabits(record.downloadMbps))")
                            .font(.mono(10))
                            .foregroundStyle(Theme.aurora)
                        Text("▲ \(Format.megabits(record.uploadMbps))")
                            .font(.mono(10))
                            .foregroundStyle(Theme.cyanBright)
                        Text("\(Int(record.latencyMs.rounded())) ms")
                            .font(.mono(10))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.vertical, 6)
                    if record.id != records.prefix(5).last?.id {
                        Divider().overlay(Theme.divider)
                    }
                }
            }
        }
        .glassCard(border: Theme.cyanBright.opacity(0.2))
    }
}
