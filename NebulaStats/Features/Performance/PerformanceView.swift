import SwiftUI

/// CPU, memory and storage in depth: 60-second history chart, per-core
/// load bars, memory breakdown, storage ring.
struct PerformanceView: View {
    @Environment(StatsHub.self) private var hub
    @State private var showsCoreInfo = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ScreenHeader(title: "Performance", showsLiveBadge: true, interval: hub.refreshInterval)
                cpuCard
                memoryCard
                storageCard
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 90)
        }
        .sheet(isPresented: $showsCoreInfo) {
            CoreInfoSheet()
        }
    }

    // MARK: - CPU

    private var cpuCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                MicroLabel(text: "CPU · 60 s", size: 9)
                Button {
                    showsCoreInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textMicro)
                }
                .accessibilityLabel("What do these numbers mean?")
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(hub.cpu.map { Format.percent($0.totalLoad) } ?? "--")
                        .font(.mono(22, .semibold))
                        .foregroundStyle(hub.cpu == nil ? Theme.textDisabled : Theme.textPrimary)
                        .contentTransition(.numericText())
                }
            }

            SparklineChart(
                values: hub.cpuHistory.values,
                color: Theme.violet,
                lineWidth: 1.8,
                showsGridlines: true,
                showsAreaFill: true
            )
            .frame(height: 64)

            if let cpu = hub.cpu {
                VStack(spacing: 6) {
                    ForEach(Array(cpu.perCoreLoad.enumerated()), id: \.offset) { index, load in
                        let isPerformanceCore = index < max(cpu.perCoreLoad.count / 3, 2)
                        CoreBarRow(
                            label: coreLabel(index: index, isPerformance: isPerformanceCore),
                            load: load,
                            color: isPerformanceCore ? Theme.violet : Theme.cyanBright
                        )
                    }
                }
            }

            Divider().overlay(Theme.divider)

            HStack {
                Text(DeviceCatalog.chipName.uppercased())
                Spacer()
                Text(hub.cpu.map { "\($0.perCoreLoad.count) CORES" } ?? "WARMING UP…")
            }
            .font(.mono(10))
            .foregroundStyle(Theme.textMuted)
        }
        .glassCard(
            border: Theme.violet.opacity(0.24),
            glow: Theme.violetCTA.opacity(0.20)
        )
    }

    private func coreLabel(index: Int, isPerformance: Bool) -> String {
        let performanceCount = max((hub.cpu?.perCoreLoad.count ?? 0) / 3, 2)
        return isPerformance ? "P\(index + 1)" : "E\(index - performanceCount + 1)"
    }

    // MARK: - Memory

    private var memoryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                MicroLabel(text: "Memory", size: 9)
                Spacer()
                if let memory = hub.memory {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(Format.bytes(memory.usedBytes))
                            .font(.mono(22, .semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .contentTransition(.numericText())
                        Text("/ \(Format.bytes(memory.totalBytes))")
                            .font(.sans(11))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }

            if let memory = hub.memory {
                SegmentedMemoryBar(memory: memory)
                HStack(spacing: 14) {
                    legendEntry("ACTIVE", Format.bytes(memory.activeBytes), Theme.cyanBright)
                    legendEntry("WIRED", Format.bytes(memory.wiredBytes), Theme.textSecondary)
                    legendEntry("COMPRESSED", Format.bytes(memory.compressedBytes), Theme.textMuted)
                }

                Divider().overlay(Theme.divider)

                HStack {
                    Text("Nebula Stats footprint")
                        .font(.sans(12))
                        .foregroundStyle(Theme.textBody)
                    Spacer()
                    Text(Format.bytes(memory.appFootprintBytes))
                        .font(.mono(12))
                        .foregroundStyle(Theme.textPrimary)
                }
            }
        }
        .glassCard(border: Theme.cyanBright.opacity(0.2))
    }

    private func legendEntry(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack(spacing: 4) {
            Text("■").font(.mono(9)).foregroundStyle(color)
            Text("\(label) \(value)").font(.mono(9)).foregroundStyle(color)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }

    // MARK: - Storage

    private var storageCard: some View {
        HStack(spacing: 16) {
            if let storage = hub.storage {
                RingChart(
                    fraction: storage.usedFraction,
                    diameter: 76, lineWidth: 9,
                    centerText: Format.percent(storage.usedFraction)
                )
                VStack(alignment: .leading, spacing: 8) {
                    MicroLabel(text: "Storage", size: 9)
                    LegendRow(color: Theme.violetBright, label: "Used",
                              value: Format.bytes(storage.usedBytes))
                    LegendRow(color: Theme.textDisabled, label: "Free",
                              value: Format.bytes(storage.freeBytes))
                    LegendRow(color: Theme.cyanBright, label: "Total",
                              value: Format.bytes(storage.totalBytes))
                }
            } else {
                MicroLabel(text: "Storage", size: 9)
            }
            Spacer(minLength: 0)
        }
        .glassCard(border: Theme.violet.opacity(0.2))
    }
}

/// Explains the CPU card's letters and numbers in plain language.
private struct CoreInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Reading the CPU card")
                    .font(.sans(18, .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button("Done") { dismiss() }
                    .font(.sans(13, .semibold))
                    .foregroundStyle(Theme.cyanBright)
            }
            .padding(.top, 6)

            infoRow(
                symbol: "P1 P2 …", color: Theme.violet,
                title: "Performance cores",
                text: "The chip's fast cores. They wake up for demanding work — games, camera, app launches — and sleep the rest of the time to save battery."
            )
            infoRow(
                symbol: "E1 E2 …", color: Theme.cyanBright,
                title: "Efficiency cores",
                text: "Slower but very power-frugal cores that handle everyday background work. It's normal for these to be busier than P-cores."
            )
            infoRow(
                symbol: "%", color: Theme.aurora,
                title: "Load",
                text: "Each bar shows how busy that core was during the last sample. The big chart tracks the average across all cores for the past 60 samples."
            )

            Text("Apple doesn't let apps read core types directly, so the P/E split is inferred from the chip's known layout.")
                .font(.sans(10))
                .foregroundStyle(Theme.textMuted)

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .presentationDetents([.medium])
        .presentationBackground {
            Color(hex: 0x121226, opacity: 0.92)
                .background(.ultraThinMaterial)
        }
        .presentationCornerRadius(28)
        .presentationDragIndicator(.visible)
    }

    private func infoRow(symbol: String, color: Color, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(symbol)
                .font(.mono(11, .semibold))
                .foregroundStyle(color)
                .frame(width: 52, alignment: .leading)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.sans(13, .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(text)
                    .font(.sans(12))
                    .foregroundStyle(Theme.textSecondary)
                    .lineSpacing(2)
            }
        }
    }
}

/// Shared screen header: bold title, optional "● LIVE · 1s" badge.
struct ScreenHeader: View {
    let title: String
    var showsLiveBadge = false
    var interval: TimeInterval = 1

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.sans(20, .bold))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            if showsLiveBadge {
                Text("● LIVE · \(Int(interval))s")
                    .font(.mono(10))
                    .foregroundStyle(Theme.aurora)
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 6)
    }
}
